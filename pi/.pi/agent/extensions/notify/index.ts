import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";
import { Text } from "@mariozechner/pi-tui";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "notify",
    label: "Send Notification",
    description: "Send a notification message via telegram using the `notify` command. Supports text, parsing mode, silent delivery, replying, and threads.",
    parameters: Type.Object({
      text: Type.String({ description: "Message text to send (required)" }),
      chat: Type.Optional(Type.String({ description: "Target chat ID (optional, uses server default)" })),
      parse_mode: Type.Optional(StringEnum(["MarkdownV2", "HTML", "Markdown"] as const)),
      silent: Type.Optional(Type.Boolean({ description: "Send without notification" })),
      reply_to: Type.Optional(Type.String({ description: "Reply to a specific message ID" })),
      thread: Type.Optional(Type.String({ description: "Send to a forum topic ID" })),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const args: string[] = ["--text", params.text];

      if (params.chat) {
        args.push("--chat", params.chat);
      }
      if (params.parse_mode) {
        args.push("--parse-mode", params.parse_mode);
      }
      if (params.silent) {
        args.push("--silent");
      }
      if (params.reply_to) {
        args.push("--reply-to", params.reply_to);
      }
      if (params.thread) {
        args.push("--thread", params.thread);
      }

      try {
        const result = await pi.exec("notify", args, { signal });
        
        if (result.code !== 0) {
          return {
             content: [{ type: "text", text: `Error sending notification:\n${result.stderr}` }],
             isError: true,
             details: { exitCode: result.code, stderr: result.stderr }
          };
        }

        return {
          content: [{ type: "text", text: `Notification sent successfully.` }],
          details: { output: result.stdout }
        };

      } catch (error: any) {
        return {
           content: [{ type: "text", text: `Failed to execute notify command: ${error.message}` }],
           isError: true,
           details: { error: error.message }
        };
      }
    },
    renderCall(args, theme) {
      let text = theme.fg("toolTitle", theme.bold("notify "));
      if (args.text) {
          const display = args.text.length > 50 ? args.text.substring(0, 47) + "..." : args.text;
          text += theme.fg("muted", `"${display}"`);
      }
      if (args.chat) text += " " + theme.fg("dim", `(chat: ${args.chat})`);
      return new Text(text, 0, 0);
    },
    renderResult(result, { expanded, isPartial }, theme) {
        if (isPartial) {
            return new Text(theme.fg("warning", "Sending..."), 0, 0);
        }
        if (result.isError) {
            const errorMsg = result.content?.[0]?.type === "text" ? result.content[0].text : "Unknown error";
            return new Text(theme.fg("error", `Failed: ${errorMsg}`), 0, 0);
        }
        return new Text(theme.fg("success", "✓ Sent"), 0, 0);
    }
  });
}
