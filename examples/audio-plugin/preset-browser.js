import { Control } from './control.js';

const ITEM_HEIGHT = 24;
const SCROLLBAR_WIDTH = 12;

export class PresetBrowser extends Control {
  constructor(x, y, width, height, presets) {
    super(x, y, '');
    this.width = width;
    this.height = height;
    this.presets = presets;
    this.scrollY = 0;
    this.selectedIndex = 0;
    this.hoveredIndex = -1;
    this.scrollbarDragging = false;
    this.scrollbarHovered = false;
  }

  get contentHeight() {
    return this.presets.length * ITEM_HEIGHT;
  }

  get maxScroll() {
    return Math.max(0, this.contentHeight - this.height);
  }

  get viewportItemCount() {
    return Math.ceil(this.height / ITEM_HEIGHT);
  }

  get scrollbarHeight() {
    if (this.contentHeight <= this.height) return this.height;
    return Math.max(30, (this.height / this.contentHeight) * this.height);
  }

  get scrollbarY() {
    if (this.maxScroll === 0) return 0;
    return (this.scrollY / this.maxScroll) * (this.height - this.scrollbarHeight);
  }

  contains(mx, my) {
    return mx >= this.x && mx <= this.x + this.width &&
      my >= this.y && my <= this.y + this.height;
  }

  scrollbarContains(mx, my) {
    const sbX = this.x + this.width - SCROLLBAR_WIDTH;
    const sbY = this.y + this.scrollbarY;
    return mx >= sbX && mx <= sbX + SCROLLBAR_WIDTH &&
      my >= sbY && my <= sbY + this.scrollbarHeight;
  }

  listContains(mx, my) {
    return mx >= this.x && mx <= this.x + this.width - SCROLLBAR_WIDTH &&
      my >= this.y && my <= this.y + this.height;
  }

  getItemIndexAt(my) {
    const relY = my - this.y + this.scrollY;
    return Math.floor(relY / ITEM_HEIGHT);
  }

  onMouseDown(mx, my) {
    if (this.scrollbarContains(mx, my)) {
      this.scrollbarDragging = true;
      this.dragStartY = my;
      this.dragStartScroll = this.scrollY;
      window.cursor = 'locked';
      return true;
    }
    if (this.listContains(mx, my)) {
      const idx = this.getItemIndexAt(my);
      if (idx >= 0 && idx < this.presets.length) {
        this.selectedIndex = idx;
      }
      return true;
    }
    return false;
  }

  onMouseMove(mx, my) {
    if (this.scrollbarDragging) {
      const deltaY = my - this.dragStartY;
      const scrollRatio = deltaY / (this.height - this.scrollbarHeight);
      this.scrollY = Math.max(0, Math.min(this.maxScroll,
        this.dragStartScroll + scrollRatio * this.maxScroll));
    } else if (this.listContains(mx, my)) {
      this.hoveredIndex = this.getItemIndexAt(my);
    } else {
      this.hoveredIndex = -1;
    }
    this.scrollbarHovered = this.scrollbarContains(mx, my);
  }

  onMouseUp() {
    if (this.scrollbarDragging) {
      window.cursor = null;
    }
    this.scrollbarDragging = false;
    this.dragging = false;
  }

  onWheel(deltaY) {
    this.scrollY = Math.max(0, Math.min(this.maxScroll, this.scrollY + deltaY * 40));
  }

  draw(ctx) {
    // Background
    ctx.fillStyle = '#222';
    ctx.fillRect(this.x, this.y, this.width, this.height);

    // Border
    ctx.strokeStyle = '#444';
    ctx.lineWidth = 1;
    ctx.strokeRect(this.x + 0.5, this.y + 0.5, this.width - 1, this.height - 1);

    // Clip to viewport
    ctx.save();
    ctx.beginPath();
    ctx.rect(this.x, this.y, this.width - SCROLLBAR_WIDTH, this.height);
    ctx.clip();

    // Draw visible items
    const firstVisible = Math.floor(this.scrollY / ITEM_HEIGHT);
    const lastVisible = Math.min(this.presets.length - 1, firstVisible + this.viewportItemCount + 1);

    for (let i = firstVisible; i <= lastVisible; i++) {
      const itemY = this.y + i * ITEM_HEIGHT - this.scrollY;

      // Selection highlight
      if (i === this.selectedIndex) {
        ctx.fillStyle = '#4a7dcc';
        ctx.fillRect(this.x + 1, itemY, this.width - SCROLLBAR_WIDTH - 2, ITEM_HEIGHT);
      } else if (i === this.hoveredIndex) {
        ctx.fillStyle = '#333';
        ctx.fillRect(this.x + 1, itemY, this.width - SCROLLBAR_WIDTH - 2, ITEM_HEIGHT);
      }

      // Preset name
      ctx.fillStyle = i === this.selectedIndex ? '#fff' : '#ccc';
      ctx.font = '13px sans';
      ctx.textAlign = 'left';
      ctx.textBaseline = 'middle';
      ctx.fillText(this.presets[i], this.x + 8, itemY + ITEM_HEIGHT / 2);
    }

    ctx.restore();

    // Scrollbar track
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(this.x + this.width - SCROLLBAR_WIDTH, this.y, SCROLLBAR_WIDTH, this.height);

    // Scrollbar thumb
    ctx.fillStyle = this.scrollbarDragging ? '#888' : (this.scrollbarHovered ? '#666' : '#444');
    ctx.fillRect(
      this.x + this.width - SCROLLBAR_WIDTH + 2,
      this.y + this.scrollbarY + 2,
      SCROLLBAR_WIDTH - 4,
      this.scrollbarHeight - 4
    );
  }
}

// Generate preset names
export function generatePresets(count) {
  const categories = ['Bass', 'Lead', 'Pad', 'Pluck', 'Keys', 'Brass', 'Strings', 'FX', 'Arp', 'Seq'];
  const adjectives = ['Fat', 'Warm', 'Bright', 'Dark', 'Soft', 'Hard', 'Deep', 'Wide', 'Tight', 'Lush',
    'Analog', 'Digital', 'Vintage', 'Modern', 'Classic', 'Epic', 'Dreamy', 'Punchy', 'Smooth', 'Gritty',
    'Ambient', 'Aggressive', 'Mellow', 'Crisp', 'Rich', 'Clean', 'Dirty', 'Hollow', 'Full', 'Thin'];
  const suffixes = ['', ' I', ' II', ' III', ' IV', ' V', ' MW', ' AT', ' 808', ' 303', ' OB', ' JP',
    ' Mini', ' Poly', ' Mono', ' Sync', ' PWM', ' FM', ' AM', ' RM'];

  const presets = [];
  for (let i = 0; i < count; i++) {
    const cat = categories[Math.floor(Math.random() * categories.length)];
    const adj = adjectives[Math.floor(Math.random() * adjectives.length)];
    const suf = suffixes[Math.floor(Math.random() * suffixes.length)];
    presets.push(`${adj} ${cat}${suf}`);
  }
  return presets;
}
