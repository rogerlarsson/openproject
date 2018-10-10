(function ($) {
    $(function() {
        var tutorial_instance;
        var preventClickHandler = function(e) {
            e.preventDefault();
            e.stopPropagation();
        };
        var onboardng_tour_steps_1 = [
            {
                'next #logo' : I18n.t('js.onboarding.steps.welcome'),
                'showSkip' : false
            },
            {
                'next #content' : I18n.t('js.onboarding.steps.project_overview'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'next #menu-sidebar' : I18n.t('js.onboarding.steps.sidebar'),
                'showSkip' : false
            },
            {
                'next .settings-menu-item' : I18n.t('js.onboarding.steps.settings'),
                'showSkip' : false
            },
            {
                'next .members-menu-item' : I18n.t('js.onboarding.steps.members'),
                'showSkip' : false
            },
            {
                'click .toggler' : I18n.t('js.onboarding.steps.wp_toggler'),
                'showSkip' : false,
                'shape' : 'circle',
                'radius' : 20,
                onBeforeStart: function () {
                    $('.enjoyhint').toggleClass('-clickable', true);
                }
            },
            {
                "click .wp-query-menu--item[data-category='default']": I18n.t('js.onboarding.steps.wp_query'),
                'showSkip' : false,
                'timeout' : 200,
                'margin' : 0,
                onBeforeStart: function () {
                    $('.enjoyhint').toggleClass('-clickable', true);
                }
            }
        ];

        var onboardng_tour_steps_2 = [
            {
                'custom .wp-table--row' : I18n.t('js.onboarding.steps.wp_list'),
                'showSkip' : false,
                'timeout' : 800,
                'margin' : 5,
                onBeforeStart: function(){
                    $('.enjoyhint').toggleClass('-clickable', true);
                    // Handle next step
                    $('.wp-table--row').dblclick(function() {
                        tutorial_instance.trigger('next');
                    });
                    $('.wp-table--cell-td.id a').click(function() {
                        tutorial_instance.trigger('next');
                    });

                    // Disable clicks on the wp context menu links
                    $('.wp-table--details-link, .wp-table-context-menu-link').addClass('-disabled').bind('click', preventClickHandler);
                }
            },
            {
                'next .work-packages-full-view--split-left' : I18n.t('js.onboarding.steps.wp_full_view'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'click .work-packages-list-view-button' : I18n.t('js.onboarding.steps.wp_back_button'),
                'showSkip' : false,
                onBeforeStart: function () {
                    $('.enjoyhint').toggleClass('-clickable', true);
                }
            },
            {
                'next .add-work-package' : I18n.t('js.onboarding.steps.wp_create_button'),
                'showSkip' : false,
                'shape' : 'circle'
            },
            {
                'click .timeline-toolbar--button' : I18n.t('js.onboarding.steps.wp_timeline_button'),
                'showSkip' : false,
                'shape' : 'circle',
                onBeforeStart: function () {
                    $('.enjoyhint').toggleClass('-clickable', true);
                }
            },
            {
                'next .work-packages-tabletimeline--timeline-side' : I18n.t('js.onboarding.steps.wp_timeline'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'next .menu-item--help' : I18n.t('js.onboarding.steps.help_menu'),
                'shape' : 'circle',
                "nextButton" : {className: "myNext", text: "Got it"},
                'showSkip' : false
            }
        ];


        $('#onboarding_tour_enjoyhint').click(function () {
            tutorial_instance = new EnjoyHint();
            tutorial_instance.set(onboardng_tour_steps_1);
            startOnboardingTutorial();
        });

        if (top.location.pathname === '/projects/project-with-no-members/work_packages')
        {
            // ToDo: Do this right
            window.setTimeout(function() {
                tutorial_instance = new EnjoyHint({
                    onSkip: function () {
                        $('.wp-table--details-link, .wp-table-context-menu-link').removeClass('-disabled').unbind('click', preventClickHandler);
                    }
                });
                tutorial_instance.set(onboardng_tour_steps_2);

                startOnboardingTutorial();
            }, 4000);
        }

        function startOnboardingTutorial() {
            tutorial_instance.run();
        }
    });
}(jQuery));
