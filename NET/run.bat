dotnet publish -c Release -r win-x64 --self-contained true /p:PublishAot=true
.\bin\Release\net9.0\win-x64\publish\Program.exe