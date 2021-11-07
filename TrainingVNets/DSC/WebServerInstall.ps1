Configuration WebServerInstall
{
    Node 'localhost'
    {
        WindowsFeature WebServer 
        {
            Ensure = "Present"
            Name   = "Web-Server"
        }
    }
}