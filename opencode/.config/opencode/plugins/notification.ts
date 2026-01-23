// System notification plugin for OpenCode
// Sends native notifications on session events

export const NotificationPlugin = async ({ $, directory, client }) => {
  const projectName = directory.split("/").pop() || "opencode";

  // Detect platform
  const isMac = process.platform === "darwin";
  const isLinux = process.platform === "linux";

  const notify = async (title: string, message: string) => {
    try {
      if (isMac) {
        // Use osascript - shows Ghostty/Terminal icon (cleaner than terminal-notifier)
        await $`osascript -e ${"display notification \"" + message + "\" with title \"" + title + "\" sound name \"Pop\""}`;
      } else if (isLinux) {
        await $`notify-send ${title} ${message}`.quiet();
      }
    } catch {
      // Ignore notification failures
    }
  };

  return {
    event: async ({ event }) => {
      try {
        if (event.type === "session.idle" || event.type === "session.error") {
          let sessionName = projectName;
          
          // Try to get session title
          try {
            const sessions = await client.session.list();
            const session = sessions.find((s: any) => s.id === event.properties?.sessionID);
            if (session?.title) {
              sessionName = session.title;
            }
          } catch {
            // Use project name as fallback
          }
          
          const title = `OpenCode: ${sessionName}`;
          const message = event.type === "session.error" ? "Error" : "Complete";
          
          await notify(title, message);
        }
      } catch (err) {
        // Log error but don't crash
        console.error("Notification plugin error:", err);
      }
    },
  };
};
