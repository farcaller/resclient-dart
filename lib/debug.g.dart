// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debug.dart';

// **************************************************************************
// TemplateGenerator
// **************************************************************************

// ignore_for_file: duplicate_ignore
// ignore_for_file: unused_local_variable
// ignore_for_file: unnecessary_string_interpolations
@GenerateFor(_cacheIndex)
TrustedHtml cacheIndex(ResClient client) {
  var $ = StringBuffer();

  var rid = '';
  final rids = client.cachedRids;
  rids.sort();
  $.writeln('<!doctype html>');

  $.write('<html lang="en">');
  $.write('<head>');
  $.write('\n  ');
  $.write('<title>');
  $.write('Res Cache');
  $.write('</title>');
  $.write('\n');
  $.write('</head>');
  $.write('\n');
  $.write('<body>');
  $.write('\n  ');
  $.write('<h2>');
  $.write('Models');
  $.write('</h2>');
  $.write('\n  ');
  $.write('<ul>');
  $.write('\n    ');
  for (var rid in template.nonNullIterable(rids)) {
    $.write('<li>');
    $.write('\n      ');
    $.write('<a href="cache/${TrustedHtml.escape.attribute(rid)}">');
    $.write('${TrustedHtml.escape(rid)}');
    if (template.nonNullBool(client.get(rid)?.item is ResCollection)) {
      $.write('<span>');
      $.write(' (collection)');
      $.write('</span>');
    }
    $.write('</a>');
    $.write('\n    ');
    $.write('</li>');
  }
  $.write('\n  ');
  $.write('</ul>');
  $.write('\n\n\n  ');
  $.write('</body>');
  $.write('</html>');

  return TrustedHtml($.toString());
}

// ignore_for_file: duplicate_ignore
// ignore_for_file: unused_local_variable
// ignore_for_file: unnecessary_string_interpolations
@GenerateFor(_cacheItem)
TrustedHtml cacheItem(CacheItem item) {
  var $ = StringBuffer();

  final yamlWriter = YamlWriter(toEncodable: (dynamic object) {
    if (object is ResModel) {
      final data = object.toJson().map((key, value) {
        if (value is ResEntry) {
          return MapEntry(key, '##RID## ${value.rid}');
        } else {
          return MapEntry(key, value);
        }
      });
      return data;
    } else if (object is ResCollection) {
      final data = object.toJson().map((value) {
        if (value is ResEntry) {
          return '##RID## ${value.rid}';
        } else {
          return value;
        }
      }).toList();
      return data;
    }
    return object.toJson();
  });
  $.writeln('<!doctype html>');

  $.write('<html lang="en">');
  $.write('<head>');
  $.write('\n  ');
  $.write('<title>');
  $.write('Res Cache - ${TrustedHtml.escape(item.rid)}');
  $.write('</title>');
  $.write('\n  ');
  $.write(
      '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.1/styles/default.min.css">');
  $.write('\n  ');
  $.write(
      '<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.1/highlight.min.js">');
  $.write('</script>');
  $.write('\n');
  $.write('</head>');
  $.write('\n');
  $.write('<body>');
  $.write('\n  ');
  $.write('<h2>');
  $.write('${TrustedHtml.escape(item.rid)}');
  $.write('</h2>');
  $.write('\n  ');
  if (template.nonNullBool(item.item != null)) {
    $.write('<pre>');
    $.write('<code class="language-yaml">');
    $.write('${TrustedHtml.escape(yamlWriter.write(item.item!))}');
    $.write('</code>');
    $.write('</pre>');
  }
  $.write('\n  ');
  $.write('<script>');
  $.write('''
    document.addEventListener('DOMContentLoaded', (event) => {
      hljs.highlightAll();
      let maybeLinks = document.getElementsByClassName('hljs-string');
      for (const link of maybeLinks) {
        if (link.textContent.startsWith(`'##RID##`)) {
          let rid = link.textContent.split(' ')[1].slice(0, -1);
          link.innerHTML = `'<a href="` + rid + `">` + rid + `</a>'`;
        }
      }
    });
  ''');
  $.write('</script>');
  $.write('\n\n\n  ');
  $.write('</body>');
  $.write('</html>');

  return TrustedHtml($.toString());
}
