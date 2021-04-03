import 'dart:io';

import 'package:grinder/grinder.dart';

void main(args) => grind(args);

@Task()
void prebuild() => File('default.env').copySync('.env');

@Task()
void prepublish() => File('publish.gitignore').copySync('.gitignore');
