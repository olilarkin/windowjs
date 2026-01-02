import { Control } from './control.js';

const KNOB_SIZE = 96;
const KNOB_FRAMES = 60;

export class Knob extends Control {
  constructor(x, y, label, spriteSheet) {
    super(x, y, label);
    this.size = KNOB_SIZE;
    this.spriteSheet = spriteSheet;
  }

  contains(mx, my) {
    const cx = this.x + this.size / 2;
    const cy = this.y + this.size / 2;
    const dist = Math.sqrt((mx - cx) ** 2 + (my - cy) ** 2);
    return dist <= this.size / 2;
  }

  onMouseDown(mx, my) {
    if (this.contains(mx, my)) {
      this.dragging = true;
      this.dragStartY = my;
      this.dragStartValue = this.value;
      window.cursor = 'locked';
      return true;
    }
    return false;
  }

  onMouseUp() {
    if (this.dragging) {
      window.cursor = null;
    }
    this.dragging = false;
  }

  onMouseMove(mx, my) {
    if (this.dragging) {
      const delta = (this.dragStartY - my) / 100;
      this.value = Math.max(0, Math.min(1, this.dragStartValue + delta));
    }
  }

  draw(ctx) {
    const frame = Math.floor(this.value * (KNOB_FRAMES - 1));
    const sy = frame * KNOB_SIZE;
    ctx.drawImage(this.spriteSheet, 0, sy, KNOB_SIZE, KNOB_SIZE,
      this.x, this.y, this.size, this.size);

    // Label
    ctx.fillStyle = '#aaa';
    ctx.font = '16px sans';
    ctx.textAlign = 'center';
    ctx.fillText(this.label, this.x + this.size / 2, this.y + this.size + 22);

    // Value
    ctx.fillStyle = '#666';
    ctx.font = '14px monospace';
    ctx.fillText((this.value * 100).toFixed(0), this.x + this.size / 2, this.y + this.size + 40);
  }
}
