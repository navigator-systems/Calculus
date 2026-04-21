package k8s

import (
	"context"
	"fmt"
	"log"

	_internal "github.com/navigator/Calculus/internal"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

type namespaceFunc func(*kubernetes.Clientset, string) (string, error)

func Namespace(action, name string) (string, error) {

	clientset, err := _internal.NewClient()
	if err != nil {
		return "", fmt.Errorf("Error creating Kubernetes client: %v", err)
	}

	actionMap := map[string]namespaceFunc{
		"create": createNamespace,
		"delete": deleteNamespace,
	}

	if actionFn, actionExists := actionMap[action]; actionExists {
		result, err := actionFn(clientset, name)
		if err != nil {
			return "", fmt.Errorf("Error executing action '%s': %v", action, err)
		}
		return result, nil
	}

	log.Println("Action not found")
	return "", fmt.Errorf("Action '%s' not supported", action)
}

func createNamespace(clientset *kubernetes.Clientset, name string) (string, error) {
	if clientset == nil {
		return "", fmt.Errorf("Kubernetes client is nil")
	}

	namespace := &corev1.Namespace{
		ObjectMeta: metav1.ObjectMeta{
			Name: name,
		},
	}

	createdNS, err := clientset.CoreV1().Namespaces().Create(context.TODO(), namespace, metav1.CreateOptions{})
	if err != nil {
		return "", fmt.Errorf("error creating Namespace: %v", err)
	}
	return createdNS.Name, nil
}

func deleteNamespace(clientset *kubernetes.Clientset, name string) (string, error) {
	if clientset == nil {
		return "", fmt.Errorf("Kubernetes client is nil")
	}

	err := clientset.CoreV1().Namespaces().Delete(context.TODO(), name, metav1.DeleteOptions{})
	if err != nil {
		return "", fmt.Errorf("error deleting Namespace: %v", err)
	}
	return name, nil
}
