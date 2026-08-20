extends GdUnitTestSuite


func test_application_composes_after_children_are_ready() -> void:
	var application := auto_free(GFApplicationLifecycleFixture.new()) as GFApplicationLifecycleFixture
	add_child(application)

	assert_bool(application.was_composed).is_true()
	assert_bool(application.ready_probe.was_configured_on_ready).is_false()
