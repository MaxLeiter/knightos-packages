import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "KnightOS Package Registry",
  description: "Alternative package registry for KnightOS. Host for 11+ packages including core libraries, applications, and ports.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
        <footer className="border-t border-zinc-200 dark:border-zinc-800 mt-12">
          <div className="max-w-4xl mx-auto p-8 text-center text-sm text-zinc-600 dark:text-zinc-400">
            Made by{" "}
            <a
              href="https://github.com/maxleiter"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 dark:text-blue-400 hover:underline"
            >
              Max Leiter
            </a>
            {" • "}
            <a
              href="https://github.com/maxleiter/knightos-packages"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 dark:text-blue-400 hover:underline"
            >
              View on GitHub
            </a>
          </div>
        </footer>
      </body>
    </html>
  );
}
