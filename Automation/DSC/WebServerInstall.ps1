Configuration WebServerInstall
{
    Node 'localhost'
    {
        WindowsFeature WebServer 
        {
            Ensure = "Present"
            Name   = "Web-Server"
        }
        WindowsFeature WebServerManagementTools 
        {
            Ensure = "Present"
            Name   = "Web-Mgmt-Console"
        }
    }
}