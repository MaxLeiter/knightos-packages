import { promises as fs } from "fs";
import path from "path";
import Link from "next/link";

interface PackageInfo {
  name: string;
  repo: string;
  full_name: string;
  version: string;
  description: string;
}

async function getPackages(): Promise<PackageInfo[]> {
  const packagesDir = path.join(process.cwd(), "packages");
  const packages: PackageInfo[] = [];

  try {
    const repos = await fs.readdir(packagesDir);

    for (const repo of repos) {
      const repoPath = path.join(packagesDir, repo);
      const stat = await fs.stat(repoPath);

      if (stat.isDirectory()) {
        const pkgs = await fs.readdir(repoPath);

        for (const pkg of pkgs) {
          const manifestPath = path.join(repoPath, pkg, "manifest.json");
          try {
            const manifestContent = await fs.readFile(manifestPath, "utf-8");
            const manifest = JSON.parse(manifestContent);
            packages.push(manifest);
          } catch (e) {
            console.error(`Error reading manifest for ${repo}/${pkg}:`, e);
          }
        }
      }
    }
  } catch (error) {
    console.error("Error reading packages directory:", error);
  }

  return packages.sort((a, b) => a.full_name.localeCompare(b.full_name));
}

export default async function Home() {
  const packages = await getPackages();

  return (
    <div className="min-h-screen p-8 pb-20 sm:p-20 bg-white dark:bg-zinc-950">
      <main className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-2 text-zinc-900 dark:text-zinc-50">
          KnightOS Package Registry
        </h1>
        <p className="text-zinc-600 dark:text-zinc-400 mb-8">
          Alternative package registry for KnightOS
        </p>

        <div className="mb-6 p-4 bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/50 rounded-lg">
          <p className="text-sm text-amber-900 dark:text-amber-200">
            <strong>Note:</strong> The official packages.knightos.org is
            currently down. This registry was created to provide continued
            access to KnightOS packages.
          </p>
        </div>

        <div className="mb-8 p-5 border border-zinc-200 dark:border-zinc-800 rounded-lg bg-zinc-50 dark:bg-zinc-900">
          <h2 className="text-xl font-semibold mb-3 text-zinc-900 dark:text-zinc-50">
            Usage
          </h2>
          <p className="mb-3 text-zinc-700 dark:text-zinc-300 text-sm">
            To use this registry with the KnightOS SDK, set the environment
            variable:
          </p>
          <code className="block bg-zinc-900 dark:bg-black text-zinc-100 dark:text-zinc-300 p-3 rounded font-mono text-sm border border-zinc-700 dark:border-zinc-800">
            export KNIGHTOS_REPOSITORY_URL=https://knightos-packages.vercel.app/
          </code>
        </div>

        <div className="mb-8">
          <h2 className="text-2xl font-semibold mb-4 text-zinc-900 dark:text-zinc-50">
            Available Packages ({packages.length})
          </h2>
          <div className="grid gap-4">
            {packages.map((pkg) => (
              <Link
                key={pkg.full_name}
                href={`/package/${pkg.repo}/${pkg.name}`}
                className="border border-zinc-200 dark:border-zinc-800 rounded-lg p-4 hover:border-zinc-400 dark:hover:border-zinc-600 transition bg-white dark:bg-zinc-900 block"
              >
                <div className="flex justify-between items-start mb-2">
                  <h3 className="text-xl font-semibold text-zinc-900 dark:text-zinc-50">
                    {pkg.full_name}
                  </h3>
                  <span className="text-sm bg-blue-100 dark:bg-blue-950 text-blue-700 dark:text-blue-300 px-2 py-1 rounded">
                    v{pkg.version}
                  </span>
                </div>
                <p className="text-zinc-600 dark:text-zinc-400 text-sm">
                  {pkg.description}
                </p>
              </Link>
            ))}
          </div>
        </div>

        <div className="mt-12 text-sm text-zinc-600 dark:text-zinc-400">
          <h3 className="font-semibold mb-2 text-zinc-900 dark:text-zinc-50">
            API Endpoints
          </h3>
          <ul className="space-y-1 font-mono">
            <li>
              <code className="text-zinc-800 dark:text-zinc-300">
                /api/v1/:repo/:name
              </code>{" "}
              - Get package manifest JSON
            </li>
            <li>
              <code className="text-zinc-800 dark:text-zinc-300">
                /:repo/:name/download
              </code>{" "}
              - Download package file
            </li>
          </ul>
        </div>
      </main>
    </div>
  );
}
