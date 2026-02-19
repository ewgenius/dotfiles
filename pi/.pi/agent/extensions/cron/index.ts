import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as cron from "node-cron";
import * as fs from "fs";
import * as path from "path";

// Define Job interface
interface Job {
  id: string;
  schedule: string;
  prompt: string;
  createdAt: number;
}

const jobsFile = path.join(process.env.HOME || "", ".pi", "cron-jobs.json");

function loadJobs(): Job[] {
  try {
    if (fs.existsSync(jobsFile)) {
      return JSON.parse(fs.readFileSync(jobsFile, "utf-8"));
    }
  } catch (e) {
    console.error("Failed to load cron jobs:", e);
  }
  return [];
}

function saveJobs(jobs: Job[]) {
  try {
    const dir = path.dirname(jobsFile);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(jobsFile, JSON.stringify(jobs, null, 2));
  } catch (e) {
    console.error("Failed to save cron jobs:", e);
  }
}

// Convert "every X unit" to standard cron
function parseToCron(schedule: string): string | null {
  if (cron.validate(schedule)) return schedule;

  const match = schedule.match(/^every (\d+)?\s*(minute|hour|day)s?$/i);
  if (match) {
    const num = match[1] ? parseInt(match[1], 10) : 1;
    const unit = match[2].toLowerCase();
    
    if (unit.startsWith("minute")) return `*/${num} * * * *`;
    if (unit.startsWith("hour")) return `0 */${num} * * *`;
    if (unit.startsWith("day")) return `0 0 */${num} * *`;
  }
  
  return null;
}

export default function (pi: ExtensionAPI) {
  let isBusy = false;
  const runningTasks = new Map<string, cron.ScheduledTask>();
  let jobs: Job[] = loadJobs();

  pi.on("agent_start", () => { isBusy = true; });
  pi.on("agent_end", () => { isBusy = false; });
  pi.on("session_shutdown", () => {
    for (const task of runningTasks.values()) task.stop();
    runningTasks.clear();
  });

  const startJob = (job: Job) => {
    if (runningTasks.has(job.id)) runningTasks.get(job.id)?.stop();

    const cronSchedule = parseToCron(job.schedule);
    if (!cronSchedule) {
      console.error(`Invalid schedule for job ${job.id}: ${job.schedule}`);
      return;
    }

    const task = cron.schedule(cronSchedule, () => {
      // Determine delivery mode: queue if busy, send immediately if not
      // Note: "followUp" works even if not streaming? Docs imply "Waits for agent to finish".
      // If agent is idle, "finish" is immediate? 
      // Actually, let's use "nextTurn" if busy to be safe, or just queue it?
      // "nextTurn" -> queued for *user prompt*. That's not what we want. We want to *trigger* a turn.
      // So "followUp" or "steer" is correct. "followUp" is safest.
      
      const options = isBusy ? { deliverAs: "followUp" as const } : undefined;
      
      try {
        pi.sendUserMessage(job.prompt, options);
      } catch (e) {
        console.error(`Failed to execute cron job ${job.id}:`, e);
      }
    });
    
    runningTasks.set(job.id, task);
  };

  jobs.forEach(startJob);

  pi.registerCommand("cron", {
    description: "Schedule a prompt. Usage: /cron <schedule> <prompt>",
    handler: async (args, ctx) => {
      if (!args) {
        ctx.ui.notify("Usage: /cron <schedule> <prompt>", "error");
        return;
      }

      const parts = args.split(" ");
      let schedule = "";
      let prompt = "";
      
      // Try parsing "every X unit"
      // "every 5 minutes ..."
      // "every minute ..."
      if (parts[0].toLowerCase() === "every") {
        // Find where the unit ends (minute/hour/day)
        let unitIndex = -1;
        for (let i = 0; i < parts.length; i++) {
          if (/^(minute|hour|day)s?$/i.test(parts[i])) {
            unitIndex = i;
            break;
          }
        }
        
        if (unitIndex !== -1) {
          schedule = parts.slice(0, unitIndex + 1).join(" ");
          prompt = parts.slice(unitIndex + 1).join(" ");
        }
      } 
      
      // Try standard cron if not parsed or valid
      if (!parseToCron(schedule)) {
        // Heuristic: try 5 or 6 parts
        const try5 = parts.slice(0, 5).join(" ");
        if (cron.validate(try5)) {
          schedule = try5;
          prompt = parts.slice(5).join(" ");
        } else {
          const try6 = parts.slice(0, 6).join(" ");
          if (cron.validate(try6)) {
            schedule = try6;
            prompt = parts.slice(6).join(" ");
          }
        }
      }

      if (!parseToCron(schedule) || !prompt.trim()) {
        ctx.ui.notify("Invalid format. Use standard cron (5 parts) or 'every [X] minute/hour/day'.", "error");
        return;
      }

      const job: Job = {
        id: Math.random().toString(36).substring(2, 8),
        schedule,
        prompt: prompt.trim(),
        createdAt: Date.now()
      };

      jobs.push(job);
      saveJobs(jobs);
      startJob(job);

      ctx.ui.notify(`Scheduled job ${job.id}`, "success");
    }
  });

  pi.registerCommand("cron-list", {
    description: "List scheduled cron jobs",
    handler: async (_args, ctx) => {
      if (jobs.length === 0) {
        ctx.ui.notify("No active jobs.", "info");
        return;
      }
      const list = jobs.map(j => `**ID:** \`${j.id}\` | **Schedule:** \`${j.schedule}\`\n> ${j.prompt}`).join("\n\n");
      pi.sendMessage({
        content: `### Active Cron Jobs\n\n${list}`,
        customType: "cron-list",
        display: true
      });
    }
  });

  pi.registerCommand("cron-remove", {
    description: "Remove a cron job by ID",
    handler: async (args, ctx) => {
      if (!args) {
        ctx.ui.notify("Usage: /cron-remove <id>", "error");
        return;
      }
      const id = args.trim();
      const idx = jobs.findIndex(j => j.id === id);
      if (idx === -1) {
        ctx.ui.notify(`Job ${id} not found`, "error");
        return;
      }

      const [removed] = jobs.splice(idx, 1);
      const task = runningTasks.get(removed.id);
      task?.stop();
      runningTasks.delete(removed.id);
      saveJobs(jobs);
      
      ctx.ui.notify(`Removed job ${id}`, "success");
    }
  });
}
