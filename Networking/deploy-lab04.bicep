param location string = resourceGroup().location
param vmName string

@allowed([
  'Standard_B1s'
  'Standard_B2s'
])
param vmSize string = 'Standard_B1s'

@description('Virtual network name')
param virtualNetworkName string = 'az104-04-vnet1'

param adminUsername string

@secure()
param adminPassword string


/* Variables */
// var nic = 'az104-04-nic'
// var subnetName = 'subnet'
// var subnet0Name = 'subnet0'
// var subnet1Name = 'subnet1'
// var computeApiVersion = '2018-06-01'
// var networkApiVersion = '2018-08-01'

/* Resources */

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.40.0.0/20'
      ]
    }
    subnets: [
      {
        name: 'Subnet1'
        properties: {
          addressPrefix: '10.40.0.0/24'
        }
      }
      {
        name: 'Subnet2'
        properties: {
          addressPrefix: '10.40.1.0/24'
        }
      }
    ]
  }
}

resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2019-11-01' = [for i in range(1, 2): {
  name: 'az104-04-pip${i}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    ipAddress: '10.40.${i-1}.4'
    dnsSettings: {
      domainNameLabel: 'az104-04-pip${i}'
    }
  }
}]


resource networkInterfaces 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(1, 2): {
  name: 'nic${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork.properties.subnets[i-1].id
          }
          publicIPAddress: {
            id: publicIPAddresses[i-1].id
          }
        }
      }
    ]
    networkSecurityGroup:{
      id: networkSecurityGroup.id
    }
  }
}]

resource windowsVMs 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(1, 2): {
  name: '${vmName}${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${vmName}${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2012-R2-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk:{
          storageAccountType:'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces[i-1].id
          properties:{
            primary: true
          }
        }
      ]
    }
    // diagnosticsProfile: {
    //   bootDiagnostics: {
    //     enabled: false
    //     storageUri:  'storageUri'
    //   }
    // }
  }
}]

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'vm-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDPInBound'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'datajoin.io'
  location: 'global'
  properties: {
  }
}

resource privateDnsSOA 'Microsoft.Network/privateDnsZones/SOA@2020-06-01' = {
  name: '@'
  parent: privateDns
  properties: {
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
    ttl: 3600
  }
}

resource symbolicname 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vnetlink01'
  location: 'global'
  parent: privateDns
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: 'lance.xyz'
  location: 'global'
  resource dnsRecord 'A@2018-05-01' = [for i in range(1, 2): {
    name: windowsVMs[i - 1].name
    properties: {
      TTL: 3600
      'ARecords': [
        {
          ipv4Address: publicIPAddresses[i - 1].properties.ipAddress
        }
      ]
    }
  }]
}
