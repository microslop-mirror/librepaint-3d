import 'package:drawlite_dart/dl.dart';
import 'package:drawlite_dart/drawlite-touch.dart';


class Slider {
    late double x, y, width, start, stop, value;
    bool pressed = false;
    
    Slider(double x, double y, double start, double stop, double value) {
        this.x = x;
        this.y = y;
        this.width = 220;
        this.start = start;
        this.stop = stop;
        this.value = value;
    }

    void setPressed(bool val) {
        this.pressed = val;
    }

    bool hoveredOver(int mouseX, int mouseY) {
        return point_rect(mouseX, mouseY, this.x, this.y - 12, this.width, 24);
    }

    void render() {
        final GetObject(
            :mouseX,
            :mouseY
        ) = get;

        final hovered = this.hoveredOver(mouseX, mouseY);

        if (this.pressed) {
            this.value = constrain(map(mouseX, this.x, this.x + this.width, this.start, this.stop), this.start, this.stop).toDouble();
        }

        // slider base
        noStroke();
        if (hovered) {
            if (this.pressed) {
                fill(145);
            } else {
                fill(97);
            }
        } else {
            fill(190);
        }
        rect(this.x, this.y, this.width, 4);
        
        var mapValue = map(this.value, this.start, this.stop, 0.0, 1.0);

        // progress
        fill(0, 100, 180);
        rect(this.x, this.y, mapValue * this.width, 4);
        
        // handle
        if (hovered) {
            if (this.pressed) {
                fill(204);
            } else {
                fill(23);
            }
        }
        rect(this.x + (mapValue * (this.width-9)), this.y - 10, 9, 24, 100);
    }
}