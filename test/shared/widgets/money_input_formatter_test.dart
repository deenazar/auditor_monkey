import 'package:auditor_monkey/shared/widgets/money_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _type(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

TextEditingValue _format(String from, String to, [int? cursor]) =>
    const MoneyInputFormatter().formatEditUpdate(
      _type(from),
      _type(to, cursor),
    );

void main() {
  test('keeps digits and one dot', () {
    expect(_format('', '12.5').text, '12.5');
    expect(_format('12', '12.5.3').text, '12.53');
    expect(_format('', '..').text, '.');
  });

  test('drops letters, spaces, signs, commas and the rupee sign', () {
    expect(_format('', 'a1b2').text, '12');
    expect(_format('', '-5').text, '5');
    expect(_format('', '₹1,23,456').text, '123456');
    expect(_format('', '1 000').text, '1000');
  });

  test('at most 2 decimals', () {
    expect(_format('1.25', '1.256').text, '1.25');
    expect(_format('', '0.999').text, '0.99');
  });

  test('at most 13 whole digits', () {
    expect(_format('', '12345678901234').text, '1234567890123');
    expect(_format('', '12345678901234.55').text, '1234567890123.55');
  });

  test('a long paste stays short', () {
    expect(_format('', '9' * 100).text.length, lessThanOrEqualTo(40));
  });

  test('clean text is returned unchanged (same object)', () {
    final TextEditingValue v = _type('12.5');
    expect(
      identical(
        const MoneyInputFormatter().formatEditUpdate(_type('12'), v),
        v,
      ),
      isTrue,
    );
  });

  test('cursor stays next to the character it was next to', () {
    final TextEditingValue v = _format('12', '1a2', 2);
    expect(v.text, '12');
    expect(v.selection.baseOffset, 1);
    expect(_format('', '1,000').selection.baseOffset, 4);
  });

  test('selection never points past the text', () {
    final TextEditingValue v = _format('1', '1aaaa', 5);
    expect(v.text, '1');
    expect(v.selection.baseOffset, 1);
    expect(v.selection.extentOffset, 1);
  });

  test('empty stays empty', () {
    expect(_format('5', '').text, '');
  });
}
