import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import path from 'path';

// Cache for 1 hour (3600 seconds)
export const revalidate = 3600;

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ repo: string; name: string }> }
) {
  const { repo, name } = await params;

  try {
    const manifestPath = path.join(
      process.cwd(),
      'packages',
      repo,
      name,
      'manifest.json'
    );

    const manifestContent = await fs.readFile(manifestPath, 'utf-8');
    const manifest = JSON.parse(manifestContent);

    return NextResponse.json(manifest, {
      headers: {
        'Cache-Control': 'public, max-age=3600, s-maxage=3600, stale-while-revalidate=86400',
      },
    });
  } catch (error) {
    console.error('Error reading manifest:', error);
    return NextResponse.json(
      { error: 'Package not found' },
      { status: 404 }
    );
  }
}
