import 'package:fpm_cli/fpm.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    printUsage();
    return;
  }

  switch (args[0]) {
    case 'scan':
      await scanCommand();
      break;
    case 'add':
      if (args.length < 2) return printUsage();
      await addCommand(args[1]);
      break;
    case 'list':
      await listCommand();
      break;
    case 'open':
      if (args.length < 2) return printUsage();
      final projectName = args[1].trim();
      await openCommand(projectName);
      break;

    case 'remove':
      if (args.length < 2) return printUsage();
      await removeCommand(args[1]);
      break;
    case 'recent':
       await recentCommand();
    default:
      printUsage();
  }
}
