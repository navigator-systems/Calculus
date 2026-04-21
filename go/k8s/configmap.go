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

type configMapActionFn func(*kubernetes.Clientset, ConfigMapData) (string, error)

type ConfigMapData struct {
	Name      string
	Namespace string
	Key       string
	Value     string
}

func ConfigMap(action, name, namespace, key, value string) (string, error) {
	clientset, err := _internal.NewClient()
	if err != nil {
		return "", fmt.Errorf("error creating Kubernetes client: %v", err)
	}

	if namespace == "" {
		namespace = "default"
	}

	data := ConfigMapData{
		Name:      name,
		Namespace: namespace,
		Key:       key,
		Value:     value,
	}

	actionMap := map[string]configMapActionFn{
		"create": createConfigMap,
		"update": updateConfigMap,
		"delete": deleteConfigMap,
	}

	if fn, exists := actionMap[action]; exists {
		result, err := fn(clientset, data)
		if err != nil {
			return "", fmt.Errorf("error executing action '%s': %v", action, err)
		}
		return result, nil
	}

	log.Println("Action not found")
	return "", fmt.Errorf("action '%s' not supported", action)
}

func createConfigMap(clientset *kubernetes.Clientset, d ConfigMapData) (string, error) {
	cm := &corev1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name:      d.Name,
			Namespace: d.Namespace,
		},
		Data: map[string]string{
			d.Key: d.Value,
		},
	}

	created, err := clientset.CoreV1().ConfigMaps(d.Namespace).Create(context.TODO(), cm, metav1.CreateOptions{})
	if err != nil {
		return "", fmt.Errorf("error creating ConfigMap: %v", err)
	}

	return created.Name, nil
}

func updateConfigMap(clientset *kubernetes.Clientset, d ConfigMapData) (string, error) {
	existing, err := clientset.CoreV1().ConfigMaps(d.Namespace).Get(context.TODO(), d.Name, metav1.GetOptions{})
	if err != nil {
		return "", fmt.Errorf("error getting ConfigMap '%s': %v", d.Name, err)
	}

	if existing.Data == nil {
		existing.Data = make(map[string]string)
	}
	existing.Data[d.Key] = d.Value

	updated, err := clientset.CoreV1().ConfigMaps(d.Namespace).Update(context.TODO(), existing, metav1.UpdateOptions{})
	if err != nil {
		return "", fmt.Errorf("error updating ConfigMap '%s': %v", d.Name, err)
	}

	return updated.Name, nil
}

func deleteConfigMap(clientset *kubernetes.Clientset, d ConfigMapData) (string, error) {
	deletePolicy := metav1.DeletePropagationForeground
	err := clientset.CoreV1().ConfigMaps(d.Namespace).Delete(context.TODO(), d.Name, metav1.DeleteOptions{
		PropagationPolicy: &deletePolicy,
	})
	if err != nil {
		return "", fmt.Errorf("error deleting ConfigMap '%s': %v", d.Name, err)
	}

	return fmt.Sprintf("ConfigMap %s deleted", d.Name), nil
}
