#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/logging/log.h>
#include <zephyr/sys/atomic.h>
#include <openthread.h>
#include <openthread/thread.h>

#if defined(CONFIG_LED_STRIP) && DT_HAS_ALIAS(led_strip)
#include <zephyr/drivers/led_strip.h>
#define LAB_HAS_ROLE_LED 1
#endif

LOG_MODULE_REGISTER(lab2_mesh, LOG_LEVEL_INF);

/* Same image on A and B: the CLI forms the network; roles are dynamic. */
#if defined(LAB_HAS_ROLE_LED)
static const struct device *const strip = DEVICE_DT_GET(DT_ALIAS(led_strip));
static atomic_t role = ATOMIC_INIT(OT_DEVICE_ROLE_DISABLED);

static const struct led_rgb role_colors[] = {
	[OT_DEVICE_ROLE_DISABLED] = { .r = 0, .g = 0, .b = 0 },
	[OT_DEVICE_ROLE_DETACHED] = { .r = 0x20, .g = 0, .b = 0 },
	[OT_DEVICE_ROLE_CHILD] = { .r = 0x20, .g = 0x18, .b = 0 },
	[OT_DEVICE_ROLE_ROUTER] = { .r = 0, .g = 0x20, .b = 0 },
	[OT_DEVICE_ROLE_LEADER] = { .r = 0, .g = 0, .b = 0x20 },
};

/* Do not access the LED driver while the OpenThread callback holds its lock. */
static void led_work_handler(struct k_work *work)
{
	ARG_UNUSED(work);
	if (!device_is_ready(strip)) {
		return;
	}
	struct led_rgb pixel = role_colors[atomic_get(&role)];

	if (led_strip_update_rgb(strip, &pixel, 1) != 0) {
		LOG_ERR("Failed to update role LED");
	}
}

static K_WORK_DEFINE(led_work, led_work_handler);
#endif

static void ot_state_changed(otChangedFlags flags, void *user_data)
{
	ARG_UNUSED(user_data);
	if (!(flags & OT_CHANGED_THREAD_ROLE)) {
		return;
	}
	otDeviceRole current = otThreadGetDeviceRole(openthread_get_default_instance());

	LOG_INF("Thread role: %s", otThreadDeviceRoleToString(current));
#if defined(LAB_HAS_ROLE_LED)
	atomic_set(&role, current);
	k_work_submit(&led_work);
#endif
}

static struct openthread_state_changed_callback state_cb = {
	.otCallback = ot_state_changed,
};

int main(void)
{
	/* Keep role reporting available even if the board LED cannot be driven. */
	openthread_state_changed_callback_register(&state_cb);
#if defined(LAB_HAS_ROLE_LED)
	if (!device_is_ready(strip)) {
		LOG_WRN("Role LED unavailable; use 'ot state'");
	} else {
		k_work_submit(&led_work);
	}
#endif
	LOG_INF("Lab 2 two-board node ready. Use the same firmware on A and B.");
	LOG_INF("Thread auto-start disabled. Commands start with 'ot'.");
	return 0;
}
