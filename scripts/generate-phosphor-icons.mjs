import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "../../..");
const defsDir = path.join(rootDir, "node_modules/phosphor-react-native/src/defs");
const outputDir = path.resolve(__dirname, "../assets");
const outputPath = path.join(outputDir, "phosphor-icons.svg");

const ICONS = [
  { name: "ArrowBendUpLeft", id: "arrow-bend-up-left", weights: ["regular"] },
  { name: "ArrowLineRight", id: "arrow-line-right", weights: ["regular"] },
  { name: "Bell", id: "bell", weights: ["regular"] },
  { name: "Book", id: "book", weights: ["regular"] },
  { name: "Bookmark", id: "bookmark", weights: ["regular", "fill"] },
  { name: "CaretDown", id: "caret-down", weights: ["regular"] },
  { name: "CaretLeft", id: "caret-left", weights: ["regular"] },
  { name: "CaretRight", id: "caret-right", weights: ["regular"] },
  { name: "Certificate", id: "certificate", weights: ["regular"] },
  { name: "ChatCircle", id: "chat-circle", weights: ["regular"] },
  { name: "Check", id: "check", weights: ["regular"] },
  { name: "Clock", id: "clock", weights: ["regular"] },
  { name: "CodeSimple", id: "code-simple", weights: ["regular"] },
  { name: "Compass", id: "compass", weights: ["regular"] },
  { name: "DotsThree", id: "dots-three", weights: ["regular"] },
  { name: "Envelope", id: "envelope", weights: ["regular"] },
  { name: "Fire", id: "fire", weights: ["regular"] },
  { name: "Gear", id: "gear", weights: ["regular"] },
  { name: "Heart", id: "heart", weights: ["regular", "fill"] },
  { name: "House", id: "house", weights: ["regular"] },
  { name: "HouseSimple", id: "house-simple", weights: ["regular"] },
  { name: "Image", id: "image", weights: ["regular"] },
  { name: "LinkSimple", id: "link-simple", weights: ["regular"] },
  { name: "ListBullets", id: "list-bullets", weights: ["regular"] },
  { name: "MagnifyingGlass", id: "magnifying-glass", weights: ["regular"] },
  { name: "Minus", id: "minus", weights: ["regular"] },
  { name: "NotePencil", id: "note-pencil", weights: ["regular"] },
  { name: "PencilSimple", id: "pencil-simple", weights: ["regular"] },
  { name: "Plus", id: "plus", weights: ["regular"] },
  { name: "PushPin", id: "push-pin", weights: ["regular"] },
  { name: "Quotes", id: "quotes", weights: ["regular"] },
  { name: "Rows", id: "rows", weights: ["regular"] },
  { name: "Share", id: "share", weights: ["regular"] },
  { name: "SignOut", id: "sign-out", weights: ["regular"] },
  { name: "Table", id: "table", weights: ["regular"] },
  { name: "TextAlignLeft", id: "text-align-left", weights: ["regular"] },
  { name: "TextB", id: "text-b", weights: ["regular"] },
  { name: "TextHTwo", id: "text-h-two", weights: ["regular"] },
  { name: "TextItalic", id: "text-italic", weights: ["regular"] },
  { name: "User", id: "user", weights: ["regular"] },
  { name: "UserPlus", id: "user-plus", weights: ["regular"] },
  { name: "Wrench", id: "wrench", weights: ["regular"] },
  { name: "X", id: "x", weights: ["regular"] },
];

const ATTR_REPLACEMENTS = [
  ["clipRule", "clip-rule"],
  ["fillRule", "fill-rule"],
  ["strokeLinecap", "stroke-linecap"],
  ["strokeLinejoin", "stroke-linejoin"],
  ["strokeMiterlimit", "stroke-miterlimit"],
  ["strokeWidth", "stroke-width"],
];

function extractWeightMarkup(fileContent, weight) {
  const weightPattern = new RegExp(
    String.raw`\[\s*'${weight}',\s*<>[\r\n]+([\s\S]*?)[\r\n]+\s*<\/>\s*,?\s*\]`,
    "m"
  );
  const match = fileContent.match(weightPattern);

  if (!match) {
    throw new Error(`Unable to find "${weight}" weight block.`);
  }

  return match[1].trim();
}

function jsxToSvg(markup) {
  let svgMarkup = markup;

  svgMarkup = svgMarkup.replace(/<([A-Z][A-Za-z0-9]*)\b/g, (_, tag) => {
    return `<${tag.toLowerCase()}`;
  });
  svgMarkup = svgMarkup.replace(/<\/([A-Z][A-Za-z0-9]*)>/g, (_, tag) => {
    return `</${tag.toLowerCase()}>`;
  });

  for (const [from, to] of ATTR_REPLACEMENTS) {
    svgMarkup = svgMarkup.replaceAll(from, to);
  }

  return svgMarkup;
}

function buildSymbolId(id, weight) {
  return weight === "fill" ? `fomio-ph-${id}-fill` : `fomio-ph-${id}`;
}

const symbols = [];

for (const icon of ICONS) {
  const filePath = path.join(defsDir, `${icon.name}.tsx`);
  const fileContent = fs.readFileSync(filePath, "utf8");

  for (const weight of icon.weights) {
    const markup = extractWeightMarkup(fileContent, weight);
    const symbolId = buildSymbolId(icon.id, weight);
    symbols.push(
      `<symbol id="${symbolId}" viewBox="0 0 256 256" fill="currentColor">${jsxToSvg(markup)}</symbol>`
    );
  }
}

const sprite = [
  '<svg xmlns="http://www.w3.org/2000/svg" style="display:none">',
  ...symbols,
  "</svg>",
  "",
].join("\n");

fs.mkdirSync(outputDir, { recursive: true });
fs.writeFileSync(outputPath, sprite, "utf8");

console.log(`Wrote ${path.relative(rootDir, outputPath)}`);
