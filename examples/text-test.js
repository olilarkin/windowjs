// Test emoji and multilingual text rendering
window.title = 'Text Rendering Test';
window.width = 600;
window.height = 500;

const canvas = window.canvas;

// Try loading system fonts
async function init() {
  // macOS emoji font
  try {
    await window.loadFont('/System/Library/Fonts/Apple Color Emoji.ttc', 'Emoji');
    console.log('Loaded Apple Color Emoji');
  } catch (e) {
    console.log('Could not load emoji font:', e);
  }

  // List available fonts
  console.log('Available fonts:', window.fonts.slice(0, 20));

  draw();
}

function draw() {
  canvas.fillStyle = '#222';
  canvas.fillRect(0, 0, canvas.width, canvas.height);

  canvas.fillStyle = '#fff';
  canvas.font = '24px sans';
  canvas.textAlign = 'left';

  let y = 40;
  const lineHeight = 40;

  // Basic text
  canvas.fillText('Basic ASCII: Hello World', 20, y); y += lineHeight;

  // Emojis (default font)
  canvas.fillText('Emojis (sans): 🎹 🎛️ 🔊 🎵 🎶 ⚡ 🌈', 20, y); y += lineHeight;

  // Try with loaded emoji font
  canvas.font = '24px Emoji';
  canvas.fillText('Emojis (Emoji): 🎹 🎛️ 🔊 🎵 🎶', 20, y); y += lineHeight;
  canvas.font = '24px sans';

  // Japanese
  canvas.fillText('Japanese: こんにちは世界', 20, y); y += lineHeight;

  // Chinese
  canvas.fillText('Chinese: 你好世界', 20, y); y += lineHeight;

  // Korean
  canvas.fillText('Korean: 안녕하세요', 20, y); y += lineHeight;

  // Arabic (RTL)
  canvas.fillText('Arabic: مرحبا بالعالم', 20, y); y += lineHeight;

  // Hebrew
  canvas.fillText('Hebrew: שלום עולם', 20, y); y += lineHeight;

  // Thai
  canvas.fillText('Thai: สวัสดีโลก', 20, y); y += lineHeight;

  // Mixed
  canvas.fillText('Mixed: Hello 世界 🌍 مرحبا', 20, y); y += lineHeight;

  // Diacritics
  canvas.fillText('Diacritics: Ñoño café naïve résumé', 20, y); y += lineHeight;

  // Math symbols
  canvas.fillText('Math: ∑ ∫ √ π ∞ ≠ ≤ ≥', 20, y); y += lineHeight;

  // Musical symbols
  canvas.fillText('Music: ♩ ♪ ♫ ♬ 𝄞 𝄢', 20, y); y += lineHeight;
}

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') window.close();
});

await init();
