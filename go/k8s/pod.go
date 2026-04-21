package k8s

import (
	"context"
	"fmt"
	"io"
	"log"

	_internal "github.com/navigator/Calculus/internal"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

func Pod(action, namespace, name, image, cmd, configMaps string) (string, error) {

	clientset, err := _internal.NewClient()
	if err != nil {
		return "", fmt.Errorf("Error creating Kubernetes client: %v", err)
	}

	data := JobData{
		Name:       name,
		Image:      image,
		Cmd:        cmd,
		Namespace:  namespace,
		ConfigMaps: _internal.ParseConfigMaps(configMaps),
	}

	actionMap := map[string]actionFn{
		"create": createPod,
		"delete": deletePod,
		"stream": streamPod,
	}

	if actionFn, actionExists := actionMap[action]; actionExists {
		result, err := actionFn(clientset, data)
		if err != nil {
			return "", fmt.Errorf("Error executing action '%s': %v", action, err)
		}
		return result, nil
	}

	log.Println("Action not found")
	return "", fmt.Errorf("Action '%s' not supported", action)

}

func createPod(clientset *kubernetes.Clientset, createPod JobData) (string, error) {
	cmd := createPod.Cmd
	cmdSlice, err := _internal.ParseCommand(cmd)
	if err != nil {
		return "", fmt.Errorf("Error parsing command: %v", err)
	}

	volumes, volumeMounts := _internal.BuildConfigMapVolumes(createPod.ConfigMaps)

	pod := &corev1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			Name: createPod.Name,
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				{
					Name:         createPod.Name + "-container",
					Image:        createPod.Image,
					Command:      cmdSlice,
					VolumeMounts: volumeMounts,
				},
			},
			Volumes:       volumes,
			RestartPolicy: corev1.RestartPolicyNever,
		},
	}

	createdPod, err := clientset.CoreV1().Pods(createPod.Namespace).Create(context.TODO(), pod, metav1.CreateOptions{})
	if err != nil {
		return "", fmt.Errorf("Error creating Pod: %v", err)
	}

	return createdPod.Name, nil
}

func deletePod(clientset *kubernetes.Clientset, deletePod JobData) (string, error) {

	err := clientset.CoreV1().Pods(deletePod.Namespace).Delete(context.TODO(), deletePod.Name, metav1.DeleteOptions{})
	if err != nil {
		return "", fmt.Errorf("Error deleting Pod: %v", err)
	}

	return deletePod.Name, nil
}

func streamPod(clientset *kubernetes.Clientset, streamPod JobData) (string, error) {
	namespace := streamPod.Namespace
	podName := streamPod.Name

	req := clientset.CoreV1().Pods(namespace).GetLogs(podName, &corev1.PodLogOptions{
		Follow: true,
	})

	stream, err := req.Stream(context.TODO())
	if err != nil {
		return "", fmt.Errorf("Error streaming Pod logs: %v", err)
	}
	defer stream.Close()
	logs, err := io.ReadAll(stream)
	if err != nil {
		return "", fmt.Errorf("Error reading Pod logs: %v", err)
	}
	return string(logs), nil
}
