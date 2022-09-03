"""
A #build-state inform should be sent to a client on connection and should define the build version of
the device software. E.g. #build-state antennasimulator-3.5a3. Deprecated in version 5
"""
struct BuildStateInform <: AbstractKatcpInform
    version::String
end

"""
A `VersionInform` should be sent to a client on connection and should define the version of the device
API. This allows the client to perform a basic sanity check that it and the device are using compati-
ble versions of the API. The minor version number should be incremented when the API changes in a
backwards compatible way (including the adding new sensors and requests or altering existing requests
to accept wider ranges of options).
"""
struct VersionInform <: AbstractKatcpInform
    version::String
end