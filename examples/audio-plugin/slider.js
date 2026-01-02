import { Control } from './control.js';

const TRACK_WIDTH = 64;
const TRACK_HEIGHT = 198;
const HANDLE_WIDTH = 70;
const HANDLE_HEIGHT = 104;

export class Slider extends Control {
  constructor(x, y, label, trackSheet, handleSheet) {
    super(x, y, label);
    this.trackWidth = TRACK_WIDTH;
    this.trackHeight = TRACK_HEIGHT;
    this.handleWidth = HANDLE_WIDTH;
    this.handleHeight = HANDLE_HEIGHT;
    this.trackSheet = trackSheet;
    this.handleSheet = handleSheet;
  }

  getHandleY() {
    const travel = this.trackHeight - this.handleHeight;
    return this.y + (1 - this.value) * travel;
  }

  contains(mx, my) {
    const hx = this.x + (this.trackWidth - this.handleWidth) / 2;
    const hy = this.getHandleY();
    return mx >= hx && mx <= hx + this.handleWidth &&
      my >= hy && my <= hy + this.handleHeight;
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
      const travel = this.trackHeight - this.handleHeight;
      const relY = my - this.y - this.handleHeight / 2;
      this.value = 1 - Math.max(0, Math.min(1, relY / travel));
    }
  }

  draw(ctx) {
    // Track
    ctx.drawImage(this.trackSheet, this.x, this.y, this.trackWidth, this.trackHeight);

    // Handle
    const hx = this.x + (this.trackWidth - this.handleWidth) / 2;
    const hy = this.getHandleY();
    ctx.drawImage(this.handleSheet, hx, hy, this.handleWidth, this.handleHeight);

    // Label
    ctx.fillStyle = '#aaa';
    ctx.font = '16px sans';
    ctx.textAlign = 'center';
    ctx.fillText(this.label, this.x + this.trackWidth / 2, this.y + this.trackHeight + 22);

    // Value
    ctx.fillStyle = '#666';
    ctx.font = '14px monospace';
    ctx.fillText((this.value * 100).toFixed(0), this.x + this.trackWidth / 2, this.y + this.trackHeight + 40);
  }
}
