// Base control class
export class Control {
  constructor(x, y, label) {
    this.x = x;
    this.y = y;
    this.label = label;
    this.value = 0.5;
    this.dragging = false;
  }

  contains(mx, my) {
    return false;
  }

  onMouseDown(mx, my) {
    if (this.contains(mx, my)) {
      this.dragging = true;
      this.dragStartY = my;
      this.dragStartValue = this.value;
      return true;
    }
    return false;
  }

  onMouseMove(mx, my) { }

  onMouseUp() {
    this.dragging = false;
  }

  draw(ctx) { }
}
