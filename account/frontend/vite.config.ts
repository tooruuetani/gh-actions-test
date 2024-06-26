import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  test: {
    include: ["**/*.test.ts", "**/*.test.tsx"],
    reporters: ["default"],
    coverage: {
      reporter: ["text"],
      all: true,
    },
  },
});
