// ESLintに引っかかる典型的な例

// ✅ no-var: const を使用
const count = 0;

// ✅ @typescript-eslint/no-explicit-any: 具体的な型を指定
function processData(data: string): string {
  return data;
}

// ✅ eqeqeq: === を使用
function isZero(n: number): boolean {
  return n === 0 || n === -0;
}

// ✅ prefer-const: const に変更
const PI = 3.14159;

// ✅ no-empty-function: 処理を追加 / 戻り値の型を明示
function doNothing(): void {
  // intentionally left empty for demo purposes
}

// ✅ 戻り値の型を明示
function calcTax(price: number): number {
  const TAX_RATE = 0.1;
  return price * TAX_RATE;
}

// ✅ 戻り値の型を明示
function greet(name: string): string {
  return `Hello, ${name}`;
}

// ✅ prefer-template: テンプレートリテラルに変更
const name = "World";
const message = `Hello, ${name}! Today is a great day.`;

// ✅ no-shadow: 別名に変更
const value = 10;
function shadowExample(): number {
  const innerValue = 20;
  return innerValue;
}

export { count, processData, isZero, PI, doNothing, calcTax, greet, message, value, shadowExample };
