package internal

import (
	"errors"
	"strings"

	corev1 "k8s.io/api/core/v1"
)

// ParseCommand splits a command string into a []string, respecting quoted substrings.
// Supports both single (') and double (") quotes.
// Example: `perl -e "print bpi(100)"` -> ["perl", "-e", "print bpi(100)"]
func ParseCommand(cmd string) ([]string, error) {
	if cmd == "" {
		return nil, errors.New("command string cannot be empty")
	}

	var parts []string
	var current []rune
	var inQuote rune = 0 // 0 = not in quote, '\'' or '"' = in that quote type

	for _, r := range cmd {
		switch {
		case inQuote != 0:
			// Inside a quoted string
			if r == inQuote {
				// End of quoted section
				inQuote = 0
			} else {
				current = append(current, r)
			}
		case r == '\'' || r == '"':
			// Start of quoted section
			inQuote = r
		case r == ' ' || r == '\t':
			// Whitespace outside quotes - end current token
			if len(current) > 0 {
				parts = append(parts, string(current))
				current = nil
			}
		default:
			current = append(current, r)
		}
	}

	// Don't forget the last token
	if len(current) > 0 {
		parts = append(parts, string(current))
	}

	if inQuote != 0 {
		return nil, errors.New("unclosed quote in command string")
	}

	if len(parts) == 0 {
		return nil, errors.New("command string contains no valid arguments")
	}

	return parts, nil
}

// ParseConfigMaps splits a comma-separated string into a slice of trimmed, non-empty names.
func ParseConfigMaps(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	result := make([]string, 0, len(parts))
	for _, p := range parts {
		if name := strings.TrimSpace(p); name != "" {
			result = append(result, name)
		}
	}
	return result
}

// BuildConfigMapVolumes returns the Volumes and VolumeMounts needed to mount each
// ConfigMap under /data/<configmap-name>. Returns nil slices when no names are given.
func BuildConfigMapVolumes(names []string) ([]corev1.Volume, []corev1.VolumeMount) {
	if len(names) == 0 {
		return nil, nil
	}
	volumes := make([]corev1.Volume, 0, len(names))
	mounts := make([]corev1.VolumeMount, 0, len(names))
	for _, cm := range names {
		volumes = append(volumes, corev1.Volume{
			Name: cm,
			VolumeSource: corev1.VolumeSource{
				ConfigMap: &corev1.ConfigMapVolumeSource{
					LocalObjectReference: corev1.LocalObjectReference{Name: cm},
				},
			},
		})
		mounts = append(mounts, corev1.VolumeMount{
			Name:      cm,
			MountPath: "/data/" + cm,
		})
	}
	return volumes, mounts
}
