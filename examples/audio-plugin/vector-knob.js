import { Control } from './control.js';

// SVG paths extracted from vector-knob.svg (translated to origin)
const KNOB_BODY = 'M 12.7,6.35 c 0,3.505729 -2.84289,6.35 -6.35,6.35 -3.5071,0 -6.35,-2.844271 -6.35,-6.35 0,-3.507109 2.84289,-6.35 6.35,-6.35 3.50711,0 6.35,2.842891 6.35,6.35';
const KNOB_INDICATOR = 'M 6.56081,0.023428 c -0.0689,-0.01517 -0.13917,-0.02342 -0.21082,-0.02342 -0.0731,0 -0.14333,0.0083 -0.21085,0.02342 v 6.405121 h 0.42167 z';

export class VectorKnob extends Control {
  constructor(x, y, label, size = 80) {
    super(x, y, label);
    this.size = size;
    this.bodyPath = new Path2D(KNOB_BODY);
    this.indicatorPath = new Path2D(KNOB_INDICATOR);
    this.bodyColor = '#333';
    this.indicatorColor = '#fff';
    this.rimColor = '#555';
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
    const scale = this.size / 12.7; // Original SVG is 12.7 units
    const centerX = this.x + this.size / 2;
    const centerY = this.y + this.size / 2;

    // Rotation angle: -135 deg at 0, +135 deg at 1 (270 deg range)
    const angle = (-135 + this.value * 270) * Math.PI / 180;

    ctx.save();
    ctx.translate(centerX, centerY);
    ctx.scale(scale, scale);

    // Draw body
    ctx.save();
    ctx.translate(-6.35, -6.35); // Center the path
    ctx.fillStyle = this.bodyColor;
    ctx.fill(this.bodyPath);
    ctx.strokeStyle = this.rimColor;
    ctx.lineWidth = 0.3;
    ctx.stroke(this.bodyPath);
    ctx.restore();

    // Draw rotated indicator
    ctx.rotate(angle);
    ctx.translate(-6.35, -6.35);
    ctx.fillStyle = this.indicatorColor;
    ctx.fill(this.indicatorPath);

    ctx.restore();

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
