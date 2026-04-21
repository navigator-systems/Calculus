package main

/*
#include <stdlib.h>
*/
import "C"
import "github.com/navigator/Calculus/k8s"

//export KJob
func KJob(action *C.char, namespace *C.char, name *C.char, image *C.char, command *C.char, configMaps *C.char) *C.char {
	goAction := C.GoString(action)
	goNameSpace := C.GoString(namespace)
	goName := C.GoString(name)
	goImage := C.GoString(image)
	goCommand := C.GoString(command)
	goConfigMaps := C.GoString(configMaps)

	result, err := k8s.Job(goAction, goNameSpace, goName, goImage, goCommand, goConfigMaps)
	if err != nil {
		return C.CString(err.Error())
	}

	return C.CString(result)
}

//export KPod
func KPod(action *C.char, namespace *C.char, name *C.char, image *C.char, command *C.char, configMaps *C.char) *C.char {
	goAction := C.GoString(action)
	goNamespace := C.GoString(namespace)
	goName := C.GoString(name)
	goImage := C.GoString(image)
	goCommand := C.GoString(command)
	goConfigMaps := C.GoString(configMaps)

	result, err := k8s.Pod(goAction, goNamespace, goName, goImage, goCommand, goConfigMaps)
	if err != nil {
		return C.CString(err.Error())
	}

	return C.CString(result)
}

//export KConfigMap
func KConfigMap(action *C.char, name *C.char, ns *C.char, key *C.char, value *C.char) *C.char {
	goAction := C.GoString(action)
	goName := C.GoString(name)
	goNs := C.GoString(ns)
	goKey := C.GoString(key)
	goValue := C.GoString(value)

	result, err := k8s.ConfigMap(goAction, goName, goNs, goKey, goValue)
	if err != nil {
		return C.CString(err.Error())
	}

	return C.CString(result)
}

//export KNamespace
func KNamespace(action *C.char, name *C.char) *C.char {
	goAction := C.GoString(action)
	goName := C.GoString(name)

	result, err := k8s.Namespace(goAction, goName)
	if err != nil {
		return C.CString(err.Error())
	}

	return C.CString(result)
}

func main() {}
