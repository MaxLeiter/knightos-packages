import { NextRequest, NextResponse } from "next/server";
import { promises as fs } from "fs";
import path from "path";

export const revalidate = 3600;

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ repo: string; name: string }> }
) {
  const { repo, name } = await params;

  try {
    const manifestPath = path.join(
      process.cwd(),
      "packages",
      repo,
      name,
      "manifest.json"
    );
    const manifestContent = await fs.readFile(manifestPath, "utf-8");
    const manifest = JSON.parse(manifestContent);

    const pkgPath = path.join(
      process.cwd(),
      "packages",
      repo,
      name,
      `${name}-${manifest.version}.pkg`
    );

    const fileBuffer = await fs.readFile(pkgPath);

    return new NextResponse(fileBuffer, {
      status: 200,
      headers: {
        "Content-Type": "application/octet-stream",
        "Content-Disposition": `attachment; filename="${name}-${manifest.version}.pkg"`,
        "Content-Length": fileBuffer.length.toString(),
        "Cache-Control": "public, max-age=31536000, immutable",
      },
    });
  } catch (error) {
    console.error("Error reading package:", error);
    return NextResponse.json({ error: "Package not found" }, { status: 404 });
  }
}
