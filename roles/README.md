# Creating a custom role

## Scenario

This scenario is from a real partner query. The partner is a CSP Direct partner, and they have an end customer that requires a high level of security and particular requirements. One of those is protecting the disk encryption keys so that the contents of their encrpypted managed disks cannot be compromised by the partner.

The standard level of access when provisioning a new tenancy and Azure subscription is to be allocated:

* Global Admin in the AAD tenancy
* Owner for the Azure subscription

The customer wants to store secrets, keys and certificates in Azure Key Vault.  They do not want the CSP partner to have access to those secrets. 

There are a number of great documentation pages for how Azure splits out the control plane (i.e. ARM level) role based access control for creation and management of the key vault itself, and the separate data plane read and write access for the secrets it holds. There are also a number of scenarios covered with disk encryption keys (DEK), key encryption keys (KEK) and bring your own key (BYOK). Finally, the Trust Center is a great resource for meeting security compliancy levels and to understand Microsoft's philosophy and transparency regarding the protection of customer data.

* <https://docs.microsoft.com/en-gb/azure/key-vault/key-vault-secure-your-key-vault>
* <https://docs.microsoft.com/en-gb/azure/security/azure-security-encryption-atrest>
* <https://azure.microsoft.com/en-gb/overview/trusted-cloud/>
* <https://www.microsoft.com/en-us/TrustCenter/CloudServices/Azure>

There is another useful document that is a little hidden away.  You will find it on the [Azure Services on CSP](https://docs.microsoft.com/en-us/azure/cloud-solution-provider/overview/azure-csp-available-services#comments) page, or you can download it directly via this link.  

## Role Based Access Control

For this scenario there are a few areas on role based access control to note.

The first is that Azure role based access control (RBAC) separate out the control plane rights and the data plane rights. Read the page on [Understand Role Definitions](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-definitions) to see how the Actions and DataActions work together.  

First of all, the default [Owner](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner) access to a subscription through Admin On Behalf Of (AOBO) means that you have access to the secrets and that can change the RBAC assignments. You can set the access policies for the Key Vault and therefore as an Owner you can allow yourself read access to the secrets.

The second is that the role assignments are hereditary and additive.  Anything assigned at the subscription level will apply to the resource groups and their resources. You can assign the 

