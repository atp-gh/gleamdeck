import { execSync } from "node:child_process";

export function run_command(command) {
  // Use Bun's synchronous subprocess if available (fast, no shell quoting
  // issues), otherwise fall back to Node's execSync.
  if (typeof Bun !== "undefined") {
    const proc = Bun.spawnSync(["sh", "-c", command]);
    if (proc.stdout) process.stdout.write(proc.stdout);
    if (proc.stderr) process.stderr.write(proc.stderr);
    return proc.exitCode ?? 0;
  }
  try {
    execSync(command, { stdio: "inherit" });
    return 0;
  } catch (e) {
    return e.status ?? 1;
  }
}
