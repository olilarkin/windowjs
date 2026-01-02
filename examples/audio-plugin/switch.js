import { Control } from './control.js';

const SWITCH_WIDTH = 60;
const SWITCH_HEIGHT = 80;

export class Switch extends Control {
  constructor(x, y, label, spriteSheet) {
    super(x, y, label);
    this.value = 0;
    this.width = SWITCH_WIDTH;
    this.height = SWITCH_HEIGHT;
    this.spriteSheet = spriteSheet;
  }

  contains(mx, my) {
    return mx >= this.x && mx <= this.x + this.width &&
      my >= this.y && my <= this.y + this.height;
  }

  onMouseDown(mx, my) {
    if (this.contains(mx, my)) {
      this.value = this.value > 0.5 ? 0 : 1;
      return true;
    }
    return false;
  }

  onMouseMove() { }

  draw(ctx) {
    const sx = this.value > 0.5 ? SWITCH_WIDTH : 0;
    ctx.drawImage(this.spriteSheet, sx, 0, SWITCH_WIDTH, SWITCH_HEIGHT,
      this.x, this.y, this.width, this.height);

    // Label
    ctx.fillStyle = '#aaa';
    ctx.font = '16px sans';
    ctx.textAlign = 'center';
    ctx.fillText(this.label, this.x + this.width / 2, this.y + this.height + 22);

    // State
    ctx.fillStyle = this.value > 0.5 ? '#4a4' : '#666';
    ctx.font = '14px monospace';
    ctx.fillText(this.value > 0.5 ? 'ON' : 'OFF', this.x + this.width / 2, this.y + this.height + 40);
  }
}
