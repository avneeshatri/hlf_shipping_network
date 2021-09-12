package main
import (
	"fmt"
	"plugin"
	.  "github.com/hyperledger/fabric/core/handlers/endorsement/api"
)
 
func main() {
    fmt.Println("hello world")
    plug, err := plugin.Open("/home/vagrant/fabric/release/linux-amd64/bin/customPlugin.so")
    symbol, err := plug.Lookup("NewPluginFactory")
    if err != nil {
	fmt.Println(err)
    }
    fmt.Println(symbol)
    addFunc, ok := symbol.(func() PluginFactory)
    if !ok {
		panic("Plugin has no 'Add(int)int' function")
	}
	// Uses the function to return results
    addition := addFunc()
    fmt.Printf("\nAddition is:%d", addition)
}
