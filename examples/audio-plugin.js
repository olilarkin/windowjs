// Audio Plugin Interface Example for windowjs
// Demonstrates interactive knobs, sliders, buttons and switches using sprite sheets

import { Knob } from './audio-plugin/knob.js';
import { VectorKnob } from './audio-plugin/vector-knob.js';
import { Slider } from './audio-plugin/slider.js';
import { Switch } from './audio-plugin/switch.js';
import { Button } from './audio-plugin/button.js';
import { PresetBrowser, generatePresets } from './audio-plugin/preset-browser.js';

window.title = 'Audio Plugin Demo';
window.width = 900;
window.height = 540;
window.resizable = true;

const canvas = window.canvas;
const controls = [];
let activeControl = null;
let presetBrowser = null;

// Base dimensions for scaling
const BASE_WIDTH = 900;
const BASE_HEIGHT = 540;

function getScale() {
  const sx = canvas.width / BASE_WIDTH;
  const sy = canvas.height / BASE_HEIGHT;
  return Math.min(sx, sy);
}

function getOffset() {
  const scale = getScale();
  const ox = (canvas.width - BASE_WIDTH * scale) / 2;
  const oy = (canvas.height - BASE_HEIGHT * scale) / 2;
  return { x: ox, y: oy };
}

// Transform screen coordinates to base coordinates
function screenToBase(sx, sy) {
  const scale = getScale();
  const offset = getOffset();
  return {
    x: (sx - offset.x) / scale,
    y: (sy - offset.y) / scale
  };
}

function draw() {
  // Clear entire canvas
  canvas.fillStyle = '#872f2fff';
  canvas.fillRect(0, 0, canvas.width, canvas.height);

  // Apply scaling transform
  const scale = getScale();
  const offset = getOffset();

  canvas.save();
  canvas.translate(offset.x, offset.y);
  canvas.scale(scale, scale);

  // Title
  canvas.fillStyle = '#000000ff';
  canvas.font = '24px sans';
  canvas.textAlign = 'center';
  canvas.fillText('Audio Plugin Demo', 340, 35);

  // Subtitle
  canvas.fillStyle = '#000000ff';
  canvas.font = '12px sans';
  canvas.fillText('Drag knobs/sliders vertically. Scroll preset list.', 340, 54);

  // Draw all controls
  for (const ctrl of controls) {
    ctrl.draw(canvas);
  }

  canvas.restore();

  requestAnimationFrame(draw);
}

window.addEventListener('mousedown', (e) => {
  const pos = screenToBase(e.x, e.y);
  for (const ctrl of controls) {
    if (ctrl.onMouseDown(pos.x, pos.y)) {
      activeControl = ctrl;
      break;
    }
  }
});

window.addEventListener('mousemove', (e) => {
  const pos = screenToBase(e.x, e.y);
  if (activeControl) {
    activeControl.onMouseMove(pos.x, pos.y);
  }
  // Always update preset browser hover state
  if (presetBrowser && !activeControl) {
    presetBrowser.onMouseMove(pos.x, pos.y);
  }
});

window.addEventListener('mouseup', () => {
  if (activeControl) {
    activeControl.onMouseUp();
    activeControl = null;
  }
});

window.addEventListener('wheel', (e) => {
  const pos = screenToBase(e.x || 0, e.y || 0);
  if (presetBrowser && presetBrowser.contains(pos.x, pos.y)) {
    presetBrowser.onWheel(e.deltaY);
  }
});

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    window.close();
  }
});

async function init() {
  // Load sprite sheets (@2x versions)
  const knobData = await File.readImageData('examples/data/plugin/knob@2x.png');
  const buttonData = await File.readImageData('examples/data/plugin/button@2x.png');
  const switchData = await File.readImageData('examples/data/plugin/switch@2x.png');
  const trackData = await File.readImageData('examples/data/plugin/slider-track@2x.png');
  const handleData = await File.readImageData('examples/data/plugin/slider-handle@2x.png');

  const knobSheet = new ImageBitmap(knobData);
  const buttonSheet = new ImageBitmap(buttonData);
  const switchSheet = new ImageBitmap(switchData);
  const sliderTrack = new ImageBitmap(trackData);
  const sliderHandle = new ImageBitmap(handleData);

  // Create preset browser on the right
  const presets = generatePresets(1000);
  presetBrowser = new PresetBrowser(680, 70, 200, 450, presets);
  controls.push(presetBrowser);

  // Create knobs row (left section)
  const knobY = 80;
  const knobSpacing = 120;
  const knobStartX = 40;

  controls.push(new Knob(knobStartX, knobY, 'Gain', knobSheet));
  controls.push(new Knob(knobStartX + knobSpacing, knobY, 'Attack', knobSheet));
  controls.push(new Knob(knobStartX + knobSpacing * 2, knobY, 'Release', knobSheet));
  controls.push(new Knob(knobStartX + knobSpacing * 3, knobY, 'Mix', knobSheet));

  // Create sliders and controls row
  const row2Y = 220;
  const row2Spacing = 120;
  const row2StartX = 40;

  controls.push(new Slider(row2StartX + 20, row2Y, 'Volume', sliderTrack, sliderHandle));
  controls.push(new Slider(row2StartX + row2Spacing + 20, row2Y, 'Pan', sliderTrack, sliderHandle));
  controls.push(new Switch(row2StartX + row2Spacing * 2 + 20, row2Y + 60, 'Bypass', switchSheet));
  controls.push(new Button(row2StartX + row2Spacing * 3, row2Y + 50, 'Trigger', buttonSheet));

  // Vector knobs (SVG-based)
  controls.push(new VectorKnob(row2StartX + row2Spacing * 4 + 30, row2Y + 10, 'Filter', 70));
  controls.push(new VectorKnob(row2StartX + row2Spacing * 4 + 30, row2Y + 130, 'Res', 70));

  // Set initial values (preset browser is at index 0)
  controls[1].value = 0.75;  // Gain
  controls[2].value = 0.2;   // Attack
  controls[3].value = 0.4;   // Release
  controls[4].value = 0.5;   // Mix
  controls[5].value = 0.8;   // Volume
  controls[6].value = 0.5;   // Pan
  controls[9].value = 0.65;  // Filter (vector knob)
  controls[10].value = 0.3;  // Res (vector knob)

  requestAnimationFrame(draw);
}

await init();
