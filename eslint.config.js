import tseslint from "@typescript-eslint/eslint-plugin";
import tsparser from "@typescript-eslint/parser";

export default [
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parser: tsparser,
    },
    plugins: {
      "@typescript-eslint": tseslint,
    },
    rules: {
      // 基本ルール
      "no-var": "error",
      "prefer-const": "error",
      eqeqeq: "error",
      "no-console": "error",
      "no-shadow": "error",
      "prefer-template": "error",

      // TypeScript ルール
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-unused-vars": "error",
      "@typescript-eslint/explicit-function-return-type": "error",
      "@typescript-eslint/no-empty-function": "error",
    },
  },
];
