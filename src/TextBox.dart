import 'package:drawlite_dart/drawlite.dart'
    show KeyboardEvent, Key;
import 'package:drawlite_dart/dl.dart';
import 'package:drawlite_dart/drawlite-touch.dart';

const KEYPAD_ENTER = 1073741912;
const KEYPAD_1 = 1073741913;
const KEYPAD_0 = 1073741922;

class TextBox {
    late double x, y, width, height;
    late String value;
    late String units;

    int selectIdx = -1;
    int selectLen = 0;
    int selectBlinkTimer = 0;

    int lastClicked = 0;

    // characters the user is allowed to type
    RegExp allowedChars = RegExp(r'[0-9]');
    int maxLength = 3;
    // called with the typed value when editing ends via Enter or clicking elsewhere
    void Function(String)? onCommit;

    TextBox(this.x, this.y, this.width, this.height, this.value, this.units);

    bool get focused => selectIdx != -1;

    void blur() {
        if (!focused) return;
        selectIdx = -1;
        selectLen = 0;
        final commit = onCommit;
        if (commit != null) {
            commit(value);
        }
    }

    // cursor range within value, ordered so start <= end
    int get _selStart => (selectLen >= 0 ? selectIdx : selectIdx + selectLen).clamp(0, value.length);
    int get _selEnd => (selectLen >= 0 ? selectIdx + selectLen : selectIdx).clamp(0, value.length);

    void _replaceSelection(String str) {
        final start = _selStart;
        value = value.substring(0, start) + str + value.substring(_selEnd);
        selectIdx = start + str.length;
        selectLen = 0;
    }
    
    double floatValue() {
        return double.parse(this.value);
    }

    int intValue() {
        return int.parse(this.value);
    }

    void mousePressed() {
        final mouseX = get.mouseX;
        final mouseY = get.mouseY;

        if (point_rect(mouseX, mouseY, this.x, this.y, this.width, this.height)) {
            final now = DateTime.now().millisecondsSinceEpoch;
            
            if (
                selectIdx == -1 || // not clicked
                now - lastClicked < 300 // double clicked
            ) {
                selectIdx = 0;
                selectLen = this.value.length;
            } else {
                final content = "${this.value}${this.units}";
                final valueWidth = textWidth(value);
                final contentWidth = textWidth(content);
                var textX = this.x + this.width - contentWidth - 10;

                // calc cursor index
                if (mouseX < textX) {
                    selectIdx = 0;
                } else if (mouseX > textX + valueWidth) {
                    selectIdx = value.length;
                } else {
                    for (int i = 0; i < value.length; i++) {
                        final chWidth = textWidth(value[i]);
                        final chCenter = textX + chWidth / 2;
                        if (mouseX < chCenter) {
                            selectIdx = i;
                            break;
                        } else if (mouseX >= chCenter && mouseX <= textX + chWidth) {
                            selectIdx = i + 1;
                            break;
                        }
                        textX += chWidth;
                    }
                }
                selectLen = 0;
                selectBlinkTimer = now;
            }

            lastClicked = now;
        } else {
            blur();
        }
    }
    
    void mouseDragged() {
        final mouseX = get.mouseX;
        final mouseY = get.mouseY;

        if (point_rect(mouseX, mouseY, this.x, this.y, this.width, this.height)) {
            final now = DateTime.now().millisecondsSinceEpoch;
            
            var selectTo = 0;
            final content = "${this.value}${this.units}";
            final valueWidth = textWidth(value);
            final contentWidth = textWidth(content);
            var textX = this.x + this.width - contentWidth - 10;

            // so that the full select works even if the user slightly drags their mouse after
            // clicking on the text box 
            if (now - lastClicked > 100 || (mouseX >= textX && mouseX <= textX + valueWidth)) {
                // calc selecting TO cursor index
                if (mouseX < textX) {
                    selectTo = 0;
                } else if (mouseX > textX + valueWidth) {
                    selectTo = value.length;
                } else {
                    for (int i = 0; i < value.length; i++) {
                        final chWidth = textWidth(value[i]);
                        final chCenter = textX + chWidth / 2;
                        if (mouseX < chCenter) {
                            selectTo = i;
                            break;
                        } else if (mouseX >= chCenter && mouseX <= textX + chWidth) {
                            selectTo = i + 1;
                            break;
                        }
                        textX += chWidth;
                    }
                }
                selectLen = selectTo - selectIdx;
                selectBlinkTimer = now;
            }
        }
    }

    void keyPressed(KeyboardEvent event) {
        if (!focused) return;

        final code = event.keyCode;
        selectBlinkTimer = DateTime.now().millisecondsSinceEpoch;

        if (code == Key.Enter || code == KEYPAD_ENTER) {
            blur();
        } else if (code == Key.Escape) {
            // leave editing without applying; the owner restores the value
            selectIdx = -1;
            selectLen = 0;
        } else if (code == Key.Backspace) {
            if (selectLen == 0 && _selStart > 0) {
                selectIdx--;
                selectLen = 1;
            }
            _replaceSelection("");
        } else if (code == Key.Delete) {
            if (selectLen == 0 && _selEnd < value.length) {
                selectLen = 1;
            }
            _replaceSelection("");
        } else if (code == Key.LeftArrow) {
            selectIdx = selectLen == 0 ? (selectIdx - 1).clamp(0, value.length) : _selStart;
            selectLen = 0;
        } else if (code == Key.RightArrow) {
            selectIdx = selectLen == 0 ? (selectIdx + 1).clamp(0, value.length) : _selEnd;
            selectLen = 0;
        } else if (code == Key.Home) {
            selectIdx = 0;
            selectLen = 0;
        } else if (code == Key.End) {
            selectIdx = value.length;
            selectLen = 0;
        } else {
            var ch = "";
            if (code >= KEYPAD_1 && code <= KEYPAD_1 + 8) {
                ch = (code - KEYPAD_1 + 1).toString();
            } else if (code == KEYPAD_0) {
                ch = "0";
            } else if (code >= 32 && code < 127) {
                ch = String.fromCharCode(code);
            }
            if (ch.isNotEmpty && allowedChars.hasMatch(ch)) {
                if (value.length - (_selEnd - _selStart) < maxLength) {
                    _replaceSelection(ch);
                }
            }
        }
    }

    void render() {
        // box
        rectMode(CORNER);
        strokeWeight(1);
        stroke(210, 215, 225);
        fill(255);
        rect(this.x, this.y, this.width, this.height);
        
        final content = "${this.value}${this.units}";
        final txtWidth = textWidth(content);
        final txtHeight = textAscent() + textDescent() + 6;

        String preSelectContent = content;
        String selectContent = "";
        String postSelectContent = "";

        // calc substrings
        if (this.selectIdx != -1) {
            if (this.selectLen >= 0) {
                preSelectContent = content.substring(0, this.selectIdx);
                int a = this.selectIdx + this.selectLen;
                if (a > value.length) {
                    a = value.length;
                }
                selectContent = content.substring(this.selectIdx, a);
                postSelectContent = content.substring(a);
            } else {
                int a = this.selectIdx + this.selectLen;
                if (a < 0) {
                    a = 0;
                }
                preSelectContent = content.substring(0, a);
                selectContent = content.substring(a, this.selectIdx);
                postSelectContent = content.substring(this.selectIdx);
            }
        }
        
        final fontSize = (this.height / 2.3).round();
        font("Open Sans", fontSize);
        textAlign(BASELINE);

        var textX = this.x + this.width - txtWidth - 10;
        final textY = this.y + this.height - txtHeight / 2;
        // pre select
        fill(0);
        text(preSelectContent, textX, textY);
        textX += textWidth(preSelectContent);

        // select
        if (selectLen != 0) {
            final selectContentWidth = textWidth(selectContent);
            fill(0, 100, 180);
            noStroke();
            rect(textX, textY - fontSize, selectContentWidth, fontSize * 1.3);
            fill(255);
            text(selectContent, textX, textY);
            textX += selectContentWidth;
        } else if (selectIdx != -1) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - selectBlinkTimer < 600) {
                stroke(1);
                line(
                    textX, textY - fontSize,
                    textX, textY - fontSize + fontSize * 1.3
                );
            } else if (now - selectBlinkTimer >= 1000) {
                selectBlinkTimer = now;
            }
            selectBlinkTimer++;
        }

        // post select
        if (postSelectContent.isNotEmpty) {
            fill(0);
            text(postSelectContent, textX, textY);
        }
    }
}