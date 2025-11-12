import { promises as fs } from "fs";
import path from "path";
import Link from "next/link";
import { notFound } from "next/navigation";

interface PackageInfo {
  name: string;
  repo: string;
  full_name: string;
  version: string;
  description: string;
  copyright?: string;
  dependencies?: string[];
}

async function getPackage(
  repo: string,
  name: string
): Promise<PackageInfo | null> {
  try {
    const manifestPath = path.join(
      process.cwd(),
      "packages",
      repo,
      name,
      "manifest.json"
    );
    const manifestContent = await fs.readFile(manifestPath, "utf-8");
    return JSON.parse(manifestContent);
  } catch {
    return null;
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ repo: string; name: string }>;
}) {
  const { repo, name } = await params;
  const pkg = await getPackage(repo, name);

  if (!pkg) {
    return {
      title: "Package Not Found",
    };
  }

  return {
    title: `${pkg.full_name} - KnightOS Package Registry`,
    description: pkg.description,
  };
}

export default async function PackagePage({
  params,
}: {
  params: Promise<{ repo: string; name: string }>;
}) {
  const { repo, name } = await params;
  const pkg = await getPackage(repo, name);

  if (!pkg) {
    notFound();
  }

  return (
    <div className="min-h-screen p-8 pb-20 sm:p-20 bg-white dark:bg-zinc-950">
      <main className="max-w-4xl mx-auto">
        <Link
          href="/"
          className="text-sm text-blue-600 dark:text-blue-400 hover:underline mb-4 inline-block"
        >
          ← Back to packages
        </Link>

        <div className="mb-6">
          <h1 className="text-4xl font-bold mb-2 text-zinc-900 dark:text-zinc-50">
            {pkg.full_name}
          </h1>
          <p className="text-xl text-zinc-600 dark:text-zinc-400">
            {pkg.description}
          </p>
        </div>

        <div className="grid gap-6">
          <div className="border border-zinc-200 dark:border-zinc-800 rounded-lg p-6 bg-white dark:bg-zinc-900">
            <h2 className="text-lg font-semibold mb-4 text-zinc-900 dark:text-zinc-50">
              Package Information
            </h2>
            <dl className="grid gap-3">
              <div>
                <dt className="text-sm font-medium text-zinc-600 dark:text-zinc-400">
                  Version
                </dt>
                <dd className="text-base text-zinc-900 dark:text-zinc-50 font-mono">
                  {pkg.version}
                </dd>
              </div>

              <div>
                <dt className="text-sm font-medium text-zinc-600 dark:text-zinc-400">
                  Repository
                </dt>
                <dd className="text-base text-zinc-900 dark:text-zinc-50">
                  {pkg.repo}
                </dd>
              </div>

              {pkg.copyright && (
                <div>
                  <dt className="text-sm font-medium text-zinc-600 dark:text-zinc-400">
                    License
                  </dt>
                  <dd className="text-base text-zinc-900 dark:text-zinc-50">
                    {pkg.copyright}
                  </dd>
                </div>
              )}

              {pkg.dependencies && pkg.dependencies.length > 0 && (
                <div>
                  <dt className="text-sm font-medium text-zinc-600 dark:text-zinc-400 mb-2">
                    Dependencies
                  </dt>
                  <dd className="space-y-1">
                    {pkg.dependencies.map((dep) => {
                      const [depRepo, depName] = dep.split("/");
                      return (
                        <Link
                          key={dep}
                          href={`/package/${depRepo}/${depName}`}
                          className="block text-blue-600 dark:text-blue-400 hover:underline font-mono text-sm"
                        >
                          {dep}
                        </Link>
                      );
                    })}
                  </dd>
                </div>
              )}
            </dl>
          </div>

          <div className="border border-zinc-200 dark:border-zinc-800 rounded-lg p-6 bg-white dark:bg-zinc-900">
            <h2 className="text-lg font-semibold mb-4 text-zinc-900 dark:text-zinc-50">
              Installation
            </h2>
            <p className="text-sm text-zinc-600 dark:text-zinc-400 mb-3">
              Install this package using the KnightOS SDK:
            </p>
            <code className="block bg-zinc-900 dark:bg-black text-zinc-100 dark:text-zinc-300 p-3 rounded font-mono text-sm border border-zinc-700 dark:border-zinc-800">
              knightos install {pkg.full_name}
            </code>
          </div>

          <div className="border border-zinc-200 dark:border-zinc-800 rounded-lg p-6 bg-white dark:bg-zinc-900">
            <h2 className="text-lg font-semibold mb-4 text-zinc-900 dark:text-zinc-50">
              Download
            </h2>
            <div className="space-y-3">
              <a
                href={`/api/v1/${pkg.repo}/${pkg.name}`}
                target="_blank"
                rel="noopener noreferrer"
                className="block text-blue-600 dark:text-blue-400 hover:underline text-sm"
              >
                View manifest JSON →
              </a>
              <a
                href={`/${pkg.repo}/${pkg.name}/download`}
                className="inline-block bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded text-sm font-medium transition"
              >
                Download {pkg.name}-{pkg.version}.pkg
              </a>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
