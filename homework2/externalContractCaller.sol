pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT
interface studentsInterface {
    function getStudentsList() external view returns (string[] memory studentsList);
}

contract ContractsCaller {
    address contractAddress=0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;

    function getStatus() public view returns(string memory) {
        string[] memory studentsList =studentsInterface(contractAddress).getStudentsList();

        if(studentsList.length <= 10){
            return 'red';
        } else if(studentsList.length >11 && studentsList.length <=20){
            return 'yellow';
        } else {
            return 'green';
        }
    }
}
