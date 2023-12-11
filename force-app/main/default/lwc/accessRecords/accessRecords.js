import { LightningElement, wire, track } from 'lwc';
    import AccessRecords from '@salesforce/apex/AccessController.getAccessRecord';

    const columns = [
        { label: 'Date requested', fieldName: 'DateRequested', type: 'date',
            cellAttributes: {
                style: 'background-color: lightblue;' 
            }
        },
        { label: 'Name', fieldName: 'Name', type: 'text',
            cellAttributes: {
                style: 'background-color: lightblue;'
            }
        },
        { label: 'Requested by', fieldName: 'OwnerName', type: 'text',
            cellAttributes: {
                style: 'background-color: lightblue;' 
            }
        },
        { label: 'Requested profile', fieldName: 'RequestedProfile', type: 'text',
            cellAttributes: {
                style: 'background-color: lightblue;' 
            }
        },
        { label: 'Requested permission set', fieldName: 'RequestedPermissionSet', type: 'text',
            cellAttributes: {
                style: 'background-color: lightblue;' 
            }
        },
        { label: 'Expiry Date', fieldName: 'ValidityDate', type: 'Date',
            cellAttributes: {
                style: 'background-color: lightblue;' 
            }
        },
        { label: 'Status', fieldName: 'Status', type: 'text',
            cellAttributes: {
                style: { fieldName: 'StatusBackground' } 
            }
        },
    ];
    
    export default class accessRecords extends LightningElement {
        @track accessRecords;
        columns = columns;
        tableData;

        @wire(AccessRecords)
        wiredAccessRecords({ error, data }) {
            if (data) {
                this.accessRecords = data.map(record => ({
                    Id: record.Id,
                    Name: record.Name,
                    OwnerName: record.Owner.Name,
                    DateRequested: record.CreatedDate,
                    RequestedProfile: record.Profile_to_Update__c,
                    RequestedPermissionSet: record.Permission_to_Update__c,
                    ValidityDate: record.Access_Expire_Date__c,
                    Status: record.Status__c,
                    StatusBackground: this.getStatusBackground(record.Status__c) // Setting StatusBackground based on status value
                }));
                this.tableData = this.accessRecords;
            } else if (error) {
                console.error('Error retrieving access records:', error);
            }
        }

        getStatusBackground(statusValue) {
            // Logic to determine background color based on status value
            if (statusValue === 'Approved') {
                return 'background-color: green;'; 
            } else if (statusValue === 'Pending') {
                return 'background-color: yellow;'; 
            } else {
                return 'background-color: red;'; 
            }
        }
    }