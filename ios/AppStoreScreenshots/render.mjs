import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");
const configPath = path.join(__dirname, "screenshot.config.json");
const templatePath = path.join(__dirname, "template.html");
const manifestPath = path.join(__dirname, "font-manifest.json");
const exportsDir = path.join(rootDir, "outputs", "appstore-exports");
const previewDir = path.join(rootDir, "outputs", "appstore-preview");
const args = process.argv.slice(2);
const has = (value) => args.includes(value);
const valueAfter = (value) => args[args.indexOf(value) + 1];
const mode = has("--release-check") ? "release-check" : has("--check") ? "check" : has("--preview") ? "preview" : "export";
const requestedLocales = has("--locales") ? valueAfter("--locales").split(",").map((value) => value.trim()).filter(Boolean) : null;
const outputRoot = has("--output-dir") ? path.resolve(valueAfter("--output-dir")) : exportsDir;
const allowDrafts = has("--allow-drafts");
const allowPlaceholders = has("--allow-placeholders");

function userError(message) { throw new Error(`[Screenshot iOS] ${message}`); }
function warning(message) { console.warn(`[Screenshot iOS] Warning: ${message}`); }
async function readJson(filePath) { return JSON.parse(await fs.readFile(filePath, "utf8")); }
function slugify(value) { return value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, ""); }
function isNonEmptyString(value) { return typeof value === "string" && value.trim() !== ""; }
function normalizedCopy(value) { return String(value).replace(/\s+/g, " ").trim(); }

function selectedLocales(config) {
  if (!requestedLocales) return config.locales;
  for (const locale of requestedLocales) if (!config.locales.includes(locale)) userError(`Unknown locale: ${locale}`);
  return requestedLocales;
}

function validateConfig(config, manifest) {
  if (!isNonEmptyString(config?.appName)) userError("appName is required.");
  if (config.schemaVersion !== 1) userError("schemaVersion must be 1 for the screenshot-ios template.");
  if (!Array.isArray(config.locales) || config.locales.length === 0) userError("locales must be a non-empty array.");
  if (!Array.isArray(config.exportDevices) || config.exportDevices.length === 0) userError("exportDevices must be a non-empty array.");
  if (!Array.isArray(config.cards) || config.cards.length === 0 || config.cards.length > 10) userError("cards must contain 1 to 10 entries.");
  if (!config.theme || !config.devices || !config.typography || !config.localizationStatus) userError("theme, devices, typography, and localizationStatus are required.");
  if (!manifest?.presets || !manifest?.stylesheets) userError("font-manifest.json is invalid.");

  for (const locale of config.locales) {
    const resolved = manifest.aliases?.[locale] || locale;
    if (!manifest.presets[resolved]) userError(`No font preset for locale: ${locale}`);
    if (!["ready", "draft"].includes(config.localizationStatus[locale])) userError(`localizationStatus.${locale} must be ready or draft.`);
  }
  for (const deviceKey of config.exportDevices) {
    const device = config.devices[deviceKey];
    if (!device) userError(`Missing device config: ${deviceKey}`);
    for (const key of ["boardWidth", "boardHeight", "paddingX", "paddingTop", "titleSize", "bodySize", "imageWidth", "imageHeight"]) {
      if (!Number.isFinite(device[key]) || device[key] <= 0) userError(`devices.${deviceKey}.${key} must be positive.`);
    }
  }
  for (const [index, card] of config.cards.entries()) {
    if (!isNonEmptyString(card.slug)) userError(`cards[${index}].slug is required.`);
    for (const locale of config.locales) {
      for (const field of ["title", "body"]) {
        const copy = card[field]?.[locale];
        if (!isNonEmptyString(copy)) userError(`cards[${index}].${field}.${locale} is required.`);
        if (copy !== normalizedCopy(copy)) userError(`cards[${index}].${field}.${locale} must be a single line without manual whitespace.`);
      }
    }
  }
}

function draftLocales(config, locales) { return locales.filter((locale) => config.localizationStatus[locale] !== "ready"); }

async function captureImage(config, deviceKey, card, locale, requireCapture) {
  const device = config.devices[deviceKey];
  const captureName = card.capture || card.slug;
  const captureRoot = path.join(__dirname, "captures", device.captureDir || deviceKey);
  const sharedLocale = config.sharedCaptureLocales?.[locale];
  const candidates = [path.join(captureRoot, sharedLocale || locale, `${captureName}.png`)];
  for (const capturePath of candidates) {
    let image;
    try { image = await fs.readFile(capturePath); } catch (error) { if (error.code === "ENOENT") continue; throw error; }
    if (image.toString("hex", 0, 8) !== "89504e470d0a1a0a") userError(`Capture must be a real PNG: ${capturePath}`);
    const width = image.readUInt32BE(16), height = image.readUInt32BE(20);
    if (deviceKey.startsWith("duo") && Math.abs(width / height - device.boardWidth / device.boardHeight) > .01) {
      userError(`Duo capture aspect ratio does not match ${deviceKey}; capture that display instead of resizing an iPhone image.`);
    }
    return { href: `data:image/png;base64,${image.toString("base64")}`, placeholder: false };
  }
  {
    if (requireCapture) userError(`Missing real capture: ${candidates.map((candidate) => path.relative(rootDir, candidate)).join(" or ")}.`);
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="900" height="1600"><rect width="100%" height="100%" rx="72" fill="#fff"/><rect x="54" y="54" width="792" height="1492" rx="56" fill="#f1f3f8"/><text x="450" y="760" text-anchor="middle" font-family="sans-serif" font-size="42" fill="#475CEF">CAPTURE NEEDED</text><text x="450" y="830" text-anchor="middle" font-family="sans-serif" font-size="28" fill="#6C7280">${config.appName} / ${deviceKey} / ${captureName}</text></svg>`;
    return { href: `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`, placeholder: true };
  }
}

async function cardsFor(config, locale, deviceKey, requireCapture, onlyCard) {
  const cards = onlyCard ? [onlyCard] : deviceCards(config, deviceKey);
  return Promise.all(cards.map(async (card) => {
    const image = await captureImage(config, deviceKey, card, locale, requireCapture);
    return {
      slug: card.slug,
      title: card.title[locale],
      body: card.body[locale],
      image: image.href,
      placeholder: image.placeholder,
      draft: config.localizationStatus[locale] !== "ready",
      alt: `${config.appName} ${card.slug} screenshot`
    };
  }));
}

function deviceCards(config, deviceKey) {
  const slugs = config.devices[deviceKey].cardSlugs;
  if (!slugs) return config.cards;
  return slugs.map(slug => {
    const card = config.cards.find(card => card.slug === slug);
    if (!card) userError(`Unknown card selection: ${deviceKey}/${slug}`);
    return card;
  });
}

async function htmlFor(config, manifest, locale, deviceKey, cards) {
  const template = await fs.readFile(templatePath, "utf8");
  const data = { config, fontManifest: manifest, locale, deviceKey, cards };
  return template.replace("__SCREENSHOT_DATA__", JSON.stringify(data).replace(/</g, "\\u003c"));
}

async function writePreview(config, manifest, locales) {
  await fs.rm(previewDir, { recursive: true, force: true });
  await fs.mkdir(previewDir, { recursive: true });
  for (const locale of locales) for (const deviceKey of config.exportDevices) {
    const html = await htmlFor(config, manifest, locale, deviceKey, await cardsFor(config, locale, deviceKey, false));
    await fs.writeFile(path.join(previewDir, `${locale}_${deviceKey}.html`), html);
  }
  console.log(`Preview files written to ${previewDir}`);
}

async function browserCheck(page, locale, deviceKey, allowDraftLayout = false) {
  await page.waitForFunction(() => window.__SCREENSHOT_READY__ === true, null, { timeout: 30000 });
  const report = await page.evaluate(({ locale, deviceKey }) => {
    const preset = window.SCREENSHOT_DATA.fontManifest.presets[window.SCREENSHOT_DATA.fontManifest.aliases[locale] || locale];
    const cards = window.__SCREENSHOT_LAYOUT__ || [];
    const failures = cards.flatMap((card) => [card.title, card.body].filter((item) => !item.fits));
    const fontChecks = [...document.querySelectorAll(".copy")].map((element) => {
      const style = getComputedStyle(element);
      const families = style.fontFamily.split(",").map((family) => family.trim().replace(/^["']|["']$/g, "")).filter(Boolean);
      return families.some((family) => document.fonts.check(`${style.fontWeight} ${style.fontSize} "${family}"`, preset.probe || element.textContent));
    });
    const board = document.querySelector(".board");
    const imagesLoaded = [...document.querySelectorAll(".screen-image")].every((image) => image.complete && image.naturalWidth > 0);
    return { failures, fontsLoaded: fontChecks.every(Boolean), imagesLoaded, width: board.offsetWidth, height: board.offsetHeight, preset: preset.family, deviceKey };
  }, { locale, deviceKey });
  if (!report.fontsLoaded) userError(`A configured font did not load for ${locale}/${deviceKey}: ${report.preset}`);
  if (!report.imagesLoaded) userError(`A required app capture did not load for ${locale}/${deviceKey}.`);
  if (report.failures.length && !allowDraftLayout) userError(`Copy exceeds the configured minimum size for ${locale}/${deviceKey}: ${report.failures.map((item) => item.text).join(" | ")}`);
  return report;
}

async function exportScreenshots(config, manifest, locales) {
  const drafts = draftLocales(config, locales);
  if (drafts.length && !allowDrafts) userError(`Draft localizations cannot export: ${drafts.join(", ")}. Use preview or complete the copy.`);
  const duoCount = config.exportDevices.filter(key => key.startsWith("duo")).reduce((count, key) => count + deviceCards(config, key).length, 0);
  if (duoCount > 10) userError("Duo outer and inner exports share one 10-image set. Select cardSlugs explicitly.");
  await fs.mkdir(outputRoot, { recursive: true });
  const statusPath = path.join(outputRoot, "export-status.json");
  await fs.writeFile(statusPath, JSON.stringify({ production_ready: false, locales, devices: config.exportDevices }));
  const { chromium } = await import("playwright");
  const browser = await chromium.launch();
  const appSlug = slugify(config.appName);
  try {
    for (const locale of locales) {
      const outputDir = path.join(outputRoot, locale);
      await fs.rm(outputDir, { recursive: true, force: true });
      await fs.mkdir(outputDir, { recursive: true });
      for (const deviceKey of config.exportDevices) {
        const device = config.devices[deviceKey];
      for (const card of deviceCards(config, deviceKey)) {
        const index = config.cards.indexOf(card);
        const page = await browser.newPage({ viewport: { width: device.boardWidth, height: device.boardHeight }, deviceScaleFactor: 1 });
        const html = await htmlFor(config, manifest, locale, deviceKey, await cardsFor(config, locale, deviceKey, !allowPlaceholders, card));
        await page.setContent(html, { waitUntil: "networkidle" });
        const report = await browserCheck(page, locale, deviceKey, allowDrafts && config.localizationStatus[locale] !== "ready");
        if (report.width !== device.boardWidth || report.height !== device.boardHeight) userError(`Board dimensions changed for ${locale}/${deviceKey}.`);
        const filename = `${String(index + 1).padStart(2, "0")}_${appSlug}_${deviceKey}_${card.slug}.png`;
        await page.locator(".board").first().screenshot({ path: path.join(outputDir, filename) });
        await page.close();
      }
      }
    }
  } finally { await browser.close(); }
  const productionReady = !allowPlaceholders && !drafts.length;
  await fs.writeFile(statusPath, JSON.stringify({ production_ready: productionReady, locales, devices: config.exportDevices }));
  if (productionReady) {
    const check = spawnSync("python3", [path.join(rootDir, "fastlane/lib/store_screenshots.py"), "--platform", "ios", "--root", outputRoot,
      "--locales", locales.join(","), "--manifest", path.join(outputRoot, "screenshot-manifest.json"), "--require-provenance"], { stdio: "inherit" });
    if (check.status !== 0) userError("Exported screenshot validation failed.");
  }
  console.log(`Exported App Store screenshots to ${outputRoot}`);
}

async function verifyReleaseRendering(config, manifest, locales) {
  const { chromium } = await import("playwright");
  const browser = await chromium.launch();
  try {
    for (const locale of locales) for (const deviceKey of config.exportDevices) {
      const device = config.devices[deviceKey];
      for (const card of deviceCards(config, deviceKey)) {
        const page = await browser.newPage({ viewport: { width: device.boardWidth, height: device.boardHeight }, deviceScaleFactor: 1 });
        const html = await htmlFor(config, manifest, locale, deviceKey, await cardsFor(config, locale, deviceKey, true, card));
        await page.setContent(html, { waitUntil: "networkidle" });
        const report = await browserCheck(page, locale, deviceKey);
        if (report.width !== device.boardWidth || report.height !== device.boardHeight) userError(`Board dimensions changed for ${locale}/${deviceKey}.`);
        await page.close();
      }
    }
  } finally { await browser.close(); }
}

const config = await readJson(configPath);
const manifest = await readJson(manifestPath);
validateConfig(config, manifest);
const locales = selectedLocales(config);
const drafts = draftLocales(config, locales);
if (drafts.length) warning(`Preview-only draft locales: ${drafts.join(", ")}`);

if (mode === "check") {
  console.log("Screenshot iOS config is valid.");
} else if (mode === "release-check") {
  if (drafts.length) userError(`Release check failed; draft locales: ${drafts.join(", ")}`);
  for (const locale of locales) for (const deviceKey of config.exportDevices) for (const card of config.cards) await captureImage(config, deviceKey, card, locale, true);
  await verifyReleaseRendering(config, manifest, locales);
  console.log("Screenshot iOS release check passed.");
} else if (mode === "preview") {
  await writePreview(config, manifest, locales);
} else {
  await exportScreenshots(config, manifest, locales);
}
