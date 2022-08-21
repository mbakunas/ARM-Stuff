$owner      = 'mbakunas'
$repo       = 'ARM-Stuff'
$workflowId = 'RgDeployApi.yml'

$tags = @"
{"environment":"sandbox", "owner":"fflinstone@extensis.net"}
"@

$inputs = @{
    'subscriptionId'    = 'f0bb6c48-80fd-445c-98cb-c38b5f817d52'
    'resourceGroupName' = 'Foo2'
    'azureRegion'       = 'Eastus2'
    'userName'          = 'fflinstone@extensis.net'
    'tags'              = $tags
}

$body = @{
    'ref' = 'main'
    'inputs' = $inputs
} | ConvertTo-Json

$headers = @{
    'Accept' = 'application/vnd.github+json'
    'Authorization' = 'token <token>'
}

$uri = "https://api.github.com/repos/$owner/$repo/actions/workflows/$workflowId/dispatches"

Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body