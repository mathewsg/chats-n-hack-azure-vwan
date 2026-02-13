
param location string = resourceGroup().location
param adminUsername string = 'azureuser'
@secure()
param adminPassword string

// Virtual WAN
resource vwan 'Microsoft.Network/virtualWans@2023-09-01' = {
  name: 'VWAN-01'
  location: location
  properties: {
    type: 'Standard'
  }
}

// Virtual Hub
resource vwanHub 'Microsoft.Network/virtualHubs@2023-09-01' = {
  name: 'VWAN-01-hub'
  location: location
  properties: {
    virtualWan: {
      id: vwan.id
    }
    addressPrefix: '10.0.0.0/24'
  }
}

resource ipGroupWorkloads 'Microsoft.Network/ipGroups@2024-07-01' = {
  location: location
  name: 'workloads'
  properties: {
    ipAddresses: [
      '10.1.0.0/16'
      '10.2.0.0/16'
    ]
  }
} 

resource ipGroupDNS 'Microsoft.Network/ipGroups@2024-07-01' = {
  location: location
  name: 'DNS'
  properties: {
    ipAddresses: [
      '10.3.0.0/16'
    ]
  }
}

resource ipGroupBastion 'Microsoft.Network/ipGroups@2024-07-01' = {
  location: location
  name: 'Bastion'
  properties: {
    ipAddresses: [
      '10.4.0.0/16'
    ]
  }
}

// Firewall Policy
resource fwpolicy 'Microsoft.Network/firewallPolicies@2024-07-01' = {
  name: 'fw-policy-01'
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

resource ApplicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-07-01' = {
  parent: fwpolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AppRules-Demo'
        priority: 300
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'Allow-msft'
            sourceAddresses: [
              '*'
            ]
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            targetFqdns: [
              '*.microsoft.com'
            ]
          }
        ]
      }  
    ]
  }
}

//resource NetworkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-07-01' = {
//  parent: fwpolicy
//  name: 'DefaultNetworkRuleCollectionGroup'
//  properties: {
//    priority: 250
//    ruleCollections: [
//      {
//        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
//        name: 'NetRules-Demo'
//        priority: 250
//        action: {
//          type: 'Allow'
//        }
//        rules: [
//          {
//            ruleType: 'NetworkRule'
//            name: 'Allow-ICMP'
//            sourceIpGroups: [
//              ipGroupWorkloads.id
//            ]
//            ipProtocols: [
//              'ICMP'
//            ]
//            destinationPorts:[
//              '*'
//            ]
//            destinationIpGroups: [
//              ipGroupWorkloads.id
//            ]
//          }
//          {
//            ruleType: 'NetworkRule'
//            name: 'string'
//            sourceIpGroups: [
//              'string list'
//            ]
//            ipProtocols: [
//              'string array'
//            ]
//            destinationPorts:[
//              'string'
//            ]
//            destinationIpGroups: [
//              'string list'
//            ]
//          }
//        ]
//      }  
//    ]
//  }
//}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: 'firewall-vwan'
  location: location
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    virtualHub: {
      id: vwanHub.id
    }
    firewallPolicy: {
      id: fwpolicy.id
    }
  }
}

// Route Table
resource routeTable 'Microsoft.Network/routeTables@2024-07-01' = {
  location: location
  name: 'demo-rt'
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'DefaultGateway'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '10.0.0.132'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

// DNS VNet
resource vnetDNS 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-DNS'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.3.0.0/16']
    }
    subnets: [
      {
        name: 'sn-inbound'
        properties: {
          addressPrefix: '10.3.0.0/24'
        }
      }
      {
        name: 'sn-outbound'
        properties: {
          addressPrefix: '10.3.1.0/24'
        }
      }
    ]
  }
}

// Peer Hub to DNS Spoke

resource HubToDnsPeer 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2024-07-01' = {
  parent: vwanHub
  name: 'hub-DNS-peer'
  properties: {
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
    remoteVirtualNetwork: {
      id: vnetDNS.id
    }
//    routingConfiguration: {
//      associatedRouteTable: {
//        id: 'string'
//      }
//      inboundRouteMap: {
//        id: 'string'
//      }
//      outboundRouteMap: {
//        id: 'string'
//      }
//      propagatedRouteTables: {
//        ids: [
//          {
//            id: 'string'
//          }
//        ]
//        labels: [
//          'string'
//        ]
//      }
//      vnetRoutes: {
//        staticRoutes: [
//          {
//            addressPrefixes: [
//              'string'
//            ]
//            name: 'string'
//            nextHopIpAddress: 'string'
//          }
//        ]
//        staticRoutesConfig: {
//          vnetLocalRouteOverrideCriteria: 'string'
//        }
//      }
//    }
  }
}

// DNS Resolver
resource dnsResolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: 'dns-resolver'
  location: location
  properties: {
    virtualNetwork: {
      id: vnetDNS.id
    }
  }
}

// Private DNS Zone
//resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
//  name: 'primary.contoso.local'
//  location: 'global'
//}

// Link DNS Zone to vnet-DNS
//resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
//  name: 'dns-link-dns-vnet'
//  parent: privateDnsZone
//  location: 'global'
//  properties: {
//    virtualNetwork: {
//      id: vnetDNS.id
//    }
//    registrationEnabled: true
//  }
//}

// Workload VNet 01
resource vnetWorkload01 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-workload-01'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/16']
    }
    subnets: [
      {
        name: 'sn-workload-01'
        properties: {
          addressPrefix: '10.1.0.0/24'
          routeTable: {
            id: routeTable.id
          }
        }
      }
    ]
  }
}

// Peer hub to workload 01 spoke
 resource HubToWorkload01Peer 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2024-07-01' = {
  parent: vwanHub
  name: 'hub-workload01-peer'
  properties: {
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
    remoteVirtualNetwork: {
      id: vnetWorkload01.id
    }
      routingConfiguration: {
        associatedRouteTable: {
          id:  resourceId('Microsoft.Network/virtualHubs/hubRouteTables', 'VWAN-01-hub', 'noneRouteTable')
      }
    } 
  }
}

// Workload VNet 02
resource vnetWorkload02 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-workload-02'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.2.0.0/16']
    }
    subnets: [
      {
        name: 'sn-workload-02'
        properties: {
          addressPrefix: '10.2.0.0/24'
          routeTable: {
            id: routeTable.id
          }          
        }
      }
    ]
  }
}

// Peer hub to workload 02 spoke
resource HubToWorkload02Peer 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2024-07-01' = {
  parent: vwanHub
  name: 'hub-workload02-peer'
  properties: {
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
    remoteVirtualNetwork: {
      id: vnetWorkload02.id
    }
    routingConfiguration: {
      associatedRouteTable: {
        id:  resourceId('Microsoft.Network/virtualHubs/hubRouteTables', 'VWAN-01-hub', 'noneRouteTable')
      }
    }  
  }
}

// Bastion VNet
resource vnetBastion 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-bastion'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.4.0.0/16']
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.4.0.0/24'
        }
      }
    ]
  }
}

// Peer hub to Bastion spoke
resource HubToBastionPeer 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2024-07-01' = {
  parent: vwanHub
  name: 'hub-Bastion-peer'
  properties: {
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
    remoteVirtualNetwork: {
      id: vnetBastion.id
    }
  }
}

// Public IP for Bastion
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'bastion-public-ip'
  location: location
      sku: {
      name: 'Standard'
    }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Bastion Host
resource bastionHost 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: 'bastion-host'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: '${vnetBastion.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}

// Network Interface 1
resource nicvm01 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-vm-workload-01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnetWorkload01.id}/subnets/sn-workload-01'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Ubuntu VM 1
resource vm01 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'vm-workload-01'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'vm-workload-01'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicvm01.id
        }
      ]
    }
  }
}


// Network Interface 2
resource nicvm02 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-vm-workload-02'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnetWorkload02.id}/subnets/sn-workload-02'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Ubuntu VM 2
resource vm02 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'vm-workload-02'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'vm-workload-02'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicvm02.id
        }
      ]
    }
  }
}

