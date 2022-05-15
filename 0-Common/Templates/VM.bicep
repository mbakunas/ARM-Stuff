targetScope = 'resourceGroup'

// VM details
param virtualMachine_Name string
param virtualMachine_Size string
param virtualMachine_Location string
param virtualMachine_DscUri string

// Network
param virtualMachine_virtualNetworkId string
param virtualMachine_subnetName string
param virtualMachine_availabiityZone string

// appGW
param virtualMachine_appGW_Id string
param virtualMachine_appGW_BackendPoolName string

// Admin user account
param virtualMachine_adminUsername string
@secure()
param virtualMachine_adminPassword string

var subnetRef = '${virtualMachine_virtualNetworkId}/subnets/${virtualMachine_subnetName}'
var virtualMachine_NicName = '${virtualMachine_Name}-NIC'
var vm = {
  osSKU: '2019-Datacenter'
  osDiskType: 'StandardSSD_LRS'
  enableHotpatching: false
  patchMode: 'Manual'
  autoShutdownStatus: 'Enabled'
  autoShutdownTime: '19:00'
  autoShutdownTimeZone: 'Eastern Standard Time'
}


resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: virtualMachine_Name
  location: virtualMachine_Location
  tags: resourceGroup().tags
  properties: {
    hardwareProfile: {
      vmSize: virtualMachine_Size
    }
    osProfile: {
      computerName: virtualMachine_Name
      adminUsername: virtualMachine_adminUsername
      adminPassword: virtualMachine_adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: vm.enableHotpatching
          patchMode: vm.patchMode
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: vm.osSKU
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachine_Name}-OsDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
  zones: [
    virtualMachine_availabiityZone
  ]
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: virtualMachine_NicName
  location: virtualMachine_Location
  tags: resourceGroup().tags
  properties: {
    ipConfigurations: [
      {
        name: virtualMachine_NicName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          applicationGatewayBackendAddressPools: [
            {
              id: '${virtualMachine_appGW_Id}/backendAddressPools/${virtualMachine_appGW_BackendPoolName}'
            }
          ]
        }
      }
    ]
  }
}

resource windowsVMDsc 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'WebServerInstall'
  location: virtualMachine_Location
  tags: resourceGroup().tags
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: '${virtualMachine_DscUri}WebServerInstall.ps1.zip'
      configurationFunction: 'WebServerInstall.ps1\\WebServerInstall'
    }
  }
}

resource virtualMachineShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${virtualMachine_Name}'
  location: virtualMachine_Location
  tags: resourceGroup().tags
  properties: {
    status: vm.autoShutdownStatus
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: vm.autoShutdownTime
    }
    timeZoneId: vm.autoShutdownTimeZone
    targetResourceId: virtualMachine.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}
