package k8s

import (
	"context"
	"fmt"
	"io"
	"log"

	_internal "github.com/navigator/Calculus/internal"

	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

type actionFn func(*kubernetes.Clientset, JobData) (string, error)

type JobData struct {
	Name       string
	Image      string
	Cmd        string
	Namespace  string
	ConfigMaps []string
}

func Job(action, namespace, name, image, cmd, configMaps string) (string, error) {

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
		"create": createJob,
		"delete": deleteJob,
		"stream": streamJob,
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

func createJob(clientset *kubernetes.Clientset, createJob JobData) (string, error) {
	cmd := createJob.Cmd
	cmdSlice, err := _internal.ParseCommand(cmd)
	if err != nil {
		return "", fmt.Errorf("Error parsing command: %v", err)
	}

	volumes, volumeMounts := _internal.BuildConfigMapVolumes(createJob.ConfigMaps)

	job := &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			Name: createJob.Name,
		},
		Spec: batchv1.JobSpec{
			Template: corev1.PodTemplateSpec{
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Name:         createJob.Name + "-container",
							Image:        createJob.Image,
							Command:      cmdSlice,
							VolumeMounts: volumeMounts,
						},
					},
					Volumes:       volumes,
					RestartPolicy: corev1.RestartPolicyNever,
				},
			},
		},
	}

	createdJob, err := clientset.BatchV1().Jobs(createJob.Namespace).Create(context.TODO(), job, metav1.CreateOptions{})
	if err != nil {
		return "", fmt.Errorf("error creating Job: %v", err)
	}

	return createdJob.Name, nil
}

func deleteJob(clientset *kubernetes.Clientset, deleteJob JobData) (string, error) {
	deletePolicy := metav1.DeletePropagationForeground
	err := clientset.BatchV1().Jobs(deleteJob.Namespace).Delete(context.TODO(), deleteJob.Name, metav1.DeleteOptions{
		PropagationPolicy: &deletePolicy,
	})
	if err != nil {
		return "", fmt.Errorf("error deleting Job: %v", err)
	}

	return fmt.Sprintf("Job %s deleted", deleteJob.Name), nil
}

func streamJob(clientset *kubernetes.Clientset, streamJob JobData) (string, error) {
	namespace := streamJob.Namespace
	name := streamJob.Name

	// Find pods belonging to this job using the job-name label
	labelSelector := fmt.Sprintf("job-name=%s", name)
	pods, err := clientset.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{
		LabelSelector: labelSelector,
	})
	if err != nil {
		return "", fmt.Errorf("error listing pods for job %s: %v", name, err)
	}

	if len(pods.Items) == 0 {
		return "", fmt.Errorf("no pods found for job %s in namespace %s", name, namespace)
	}

	// Get logs from the first pod
	podName := pods.Items[0].Name
	req := clientset.CoreV1().Pods(namespace).GetLogs(podName, &corev1.PodLogOptions{})
	podLogs, err := req.Stream(context.TODO())
	if err != nil {
		return "", fmt.Errorf("error getting logs for pod %s: %v", podName, err)
	}
	defer podLogs.Close()

	logs, err := io.ReadAll(podLogs)
	if err != nil {
		return "", fmt.Errorf("error reading logs: %v", err)
	}

	return string(logs), nil
}
