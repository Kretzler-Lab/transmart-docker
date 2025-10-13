cd transmart-data
echo tmpassword | sudo -S bash -c "export PENTAHO_DI_JAVA_OPTIONS="-Xmx2g" && export _JAVA_OPTIONS=-Xmx8G && source ./vars && make -C samples/postgres load_expression_$1"
