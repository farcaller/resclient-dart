// Copyright 2022 Vladimir Pouzanov <farcaller@gmail.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:html_template/html_template.dart';
import 'package:res_client/client.dart';
import 'package:res_client/model.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'cache/cache_item.dart';

part 'debug.g.dart';

@template
void _cacheIndex(ResClient client) {
  var rid = '';
  final rids = client.cachedRids;
  rids.sort();

  '<!doctype html>';
  '''
<html lang="en">
<head>
  <title>Res Cache</title>
</head>
<body>
  <h2>Models</h2>
  <ul>
    <li *for="$rid in $rids">
      <a href="cache/$rid">$rid<span *if=${client.get(rid)?.item is ResCollection}> (collection)</span></a>
    </li>
  </ul>
</body>
</html>
  ''';
}

@template
void _cacheItem(CacheItem item) {
  final yamlWriter = YAMLWriter();
  yamlWriter.toEncodable = (dynamic object) {
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
  };
  '<!doctype html>';
  '''
<html lang="en">
<head>
  <title>Res Cache - ${item.rid}</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.1/styles/default.min.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.1/highlight.min.js"></script>
</head>
<body>
  <h2>${item.rid}</h2>
  <pre *if="${item.item != null}"><code class="language-yaml">${yamlWriter.write(item.item!)}</code></pre>
  <script>
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
  </script>
</body>
</html>
  ''';
}
