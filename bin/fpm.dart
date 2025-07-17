
import 'package:fpm_cli/fpm.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    printUsage();
    return;
  }

  switch (args[0]) {
    case 'scan':
      await scan();
      break;
    case 'add':
      if (args.length < 2) return printUsage();
      await addProject(args[1]);
      break;
    case 'list':
      await listProjects();
      break;
    case 'open':
      if (args.length < 2) return printUsage();
      final projectName = args[1].trim();
      await openProject(projectName);
      break;

    case 'remove':
      if (args.length < 2) return printUsage();
      await removeProject(args[1]);
      break;
    default:
      printUsage();
  }
}

