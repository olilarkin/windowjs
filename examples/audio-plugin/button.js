import { Control } from './control.js';

const BUTTON_SIZE = 100;
const BUTTON_FRAMES = 10;

export class Button extends Control {
  constructor(x, y, label, spriteSheet) {
    super(x, y, label);
    this.value = 0;
    this.size = BUTTON_SIZE;
    this.pressed = false;
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
      this.pressed = true;
      this.value = 1;
      return true;
    }
    return false;
  }

  onMouseUp() {
    this.pressed = false;
    this.value = 0;
  }

  onMouseMove() { }

  draw(ctx) {
    // Button has 10 frames, use first for off, last for pressed
    const frame = this.pressed ? BUTTON_FRAMES - 1 : 0;
    const sy = frame * BUTTON_SIZE;
    ctx.drawImage(this.spriteSheet, 0, sy, BUTTON_SIZE, BUTTON_SIZE,
      this.x, this.y, this.size, this.size);

    // Label
    ctx.fillStyle = '#aaa';
    ctx.font = '16px sans';
    ctx.textAlign = 'center';
    ctx.fillText(this.label, this.x + this.size / 2, this.y + this.size + 22);
  }
}
