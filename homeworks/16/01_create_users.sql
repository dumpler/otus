DROP USER IF EXISTS 'client'@'%';
DROP USER IF EXISTS 'manager'@'%';

CREATE USER 'client'@'%' IDENTIFIED BY 'client_pass';
CREATE USER 'manager'@'%' IDENTIFIED BY 'manager_pass';
